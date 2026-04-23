#!/usr/bin/env python3
"""
Bridge Script: Claude Code → doobidoo → LM Studio

Orchestrates plan execution from Claude Code (stored in doobidoo SQLite)
to local LM Studio for cost-effective execution.

Usage:
    python bridge.py              # Execute all pending plans
    python bridge.py --list       # List pending plans
    python bridge.py --plan ID    # Execute specific plan
    python bridge.py --health     # Check LM Studio connectivity

Requires:
    - doobidoo MCP server with SQLite backend (~/.mcp-memory-service/)
    - LM Studio running on localhost:1234
    - httpx: pip install httpx
"""

from __future__ import annotations

import argparse
import ast
import json
import logging
import shutil
import sqlite3
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any

try:
    import httpx
except ImportError:
    print("Error: httpx required. Install with: pip install httpx")
    sys.exit(1)


# === Configuration ===

DOOBIDOO_DB = Path.home() / ".mcp-memory-service" / "memories.db"
LM_STUDIO_URL = "http://localhost:1234/v1/chat/completions"
LM_STUDIO_TIMEOUT = 120.0
DEFAULT_MODEL = "default"  # LM Studio uses loaded model

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-7s | %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("bridge")


# === Data Classes ===


@dataclass
class StepResult:
    """Result of executing a single step."""

    step_id: int
    success: bool
    output: str
    error: str | None = None
    retries: int = 0


@dataclass
class PlanResult:
    """Result of executing a complete plan."""

    plan_id: str
    success: bool
    steps: list[StepResult] = field(default_factory=list)
    error: str | None = None


# === Doobidoo Reader ===


class DoobidooReader:
    """Direct SQLite access to doobidoo memory database."""

    def __init__(self, db_path: Path = DOOBIDOO_DB):
        self.db_path = db_path
        if not db_path.exists():
            raise FileNotFoundError(f"doobidoo database not found: {db_path}")

    def _connect(self) -> sqlite3.Connection:
        return sqlite3.connect(self.db_path)

    def get_pending_plans(self) -> list[dict[str, Any]]:
        """Fetch all plans with status=pending."""
        plans = []
        with self._connect() as conn:
            cursor = conn.execute(
                """
                SELECT id, content, metadata, created_at
                FROM memories
                WHERE content LIKE '%"$schema": "bridge-plan-v1"%'
                ORDER BY created_at DESC
                """
            )
            for row in cursor:
                try:
                    content = json.loads(row[1])
                    if content.get("status") == "pending":
                        plans.append(
                            {
                                "db_id": row[0],
                                "plan": content,
                                "metadata": json.loads(row[2]) if row[2] else {},
                                "created_at": row[3],
                            }
                        )
                except json.JSONDecodeError:
                    continue
        return plans

    def get_plan_by_id(self, plan_id: str) -> dict[str, Any] | None:
        """Fetch a specific plan by its plan ID."""
        with self._connect() as conn:
            cursor = conn.execute(
                """
                SELECT id, content, metadata, created_at
                FROM memories
                WHERE content LIKE ?
                ORDER BY created_at DESC
                LIMIT 1
                """,
                (f'%"id": "{plan_id}"%',),
            )
            row = cursor.fetchone()
            if row:
                try:
                    content = json.loads(row[1])
                    if content.get("$schema") == "bridge-plan-v1":
                        return {
                            "db_id": row[0],
                            "plan": content,
                            "metadata": json.loads(row[2]) if row[2] else {},
                            "created_at": row[3],
                        }
                except json.JSONDecodeError:
                    pass
        return None

    def update_plan_status(self, db_id: str, status: str) -> None:
        """Update plan status in the database."""
        with self._connect() as conn:
            cursor = conn.execute(
                "SELECT content FROM memories WHERE id = ?", (db_id,)
            )
            row = cursor.fetchone()
            if row:
                content = json.loads(row[0])
                content["status"] = status
                conn.execute(
                    "UPDATE memories SET content = ? WHERE id = ?",
                    (json.dumps(content), db_id),
                )
                conn.commit()

    def store_result(self, plan_id: str, result: PlanResult) -> None:
        """Store execution result as a new memory entry."""
        result_data = {
            "type": "bridge_result",
            "plan_id": plan_id,
            "success": result.success,
            "executed_at": datetime.now().isoformat(),
            "steps": [
                {
                    "id": s.step_id,
                    "success": s.success,
                    "output": s.output[:2000],  # Truncate for storage
                    "error": s.error,
                    "retries": s.retries,
                }
                for s in result.steps
            ],
            "error": result.error,
        }

        with self._connect() as conn:
            conn.execute(
                """
                INSERT INTO memories (id, content, metadata, created_at)
                VALUES (?, ?, ?, ?)
                """,
                (
                    f"result_{plan_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
                    json.dumps(result_data),
                    json.dumps({"tags": ["result", plan_id]}),
                    datetime.now().isoformat(),
                ),
            )
            conn.commit()


# === LM Studio Client ===


class LMStudioClient:
    """HTTP client for LM Studio API."""

    def __init__(self, base_url: str = LM_STUDIO_URL, timeout: float = LM_STUDIO_TIMEOUT):
        self.base_url = base_url
        self.timeout = timeout
        self.client = httpx.Client(timeout=timeout)

    def health_check(self) -> bool:
        """Check if LM Studio is running and responsive."""
        try:
            # Try models endpoint first
            response = self.client.get(
                self.base_url.replace("/chat/completions", "/models")
            )
            return response.status_code == 200
        except httpx.RequestError:
            return False

    def generate(self, prompt: str, system: str | None = None) -> str:
        """Generate completion from LM Studio."""
        messages = []
        if system:
            messages.append({"role": "system", "content": system})
        messages.append({"role": "user", "content": prompt})

        response = self.client.post(
            self.base_url,
            json={
                "model": DEFAULT_MODEL,
                "messages": messages,
                "temperature": 0.3,
                "max_tokens": 4096,
            },
        )
        response.raise_for_status()
        data = response.json()
        return data["choices"][0]["message"]["content"]

    def close(self) -> None:
        """Close the HTTP client."""
        self.client.close()


# === Validators ===


class Validator:
    """Validation functions for step outputs."""

    @staticmethod
    def validate(output: str, validation: dict[str, Any]) -> tuple[bool, str | None]:
        """Validate output based on validation config."""
        val_type = validation.get("type", "non_empty")

        if val_type == "non_empty":
            return Validator.non_empty(output)
        elif val_type == "json":
            return Validator.json_valid(output)
        elif val_type == "syntax_check":
            return Validator.python_syntax(output)
        elif val_type == "contains_keys":
            keys = validation.get("keys", [])
            return Validator.contains_keys(output, keys)
        else:
            return True, None

    @staticmethod
    def non_empty(output: str) -> tuple[bool, str | None]:
        """Check output is not empty or whitespace."""
        if output and output.strip():
            return True, None
        return False, "Output is empty"

    @staticmethod
    def json_valid(output: str) -> tuple[bool, str | None]:
        """Check output is valid JSON."""
        try:
            # Try to extract JSON from markdown code blocks
            content = output
            if "```json" in output:
                start = output.find("```json") + 7
                end = output.find("```", start)
                if end > start:
                    content = output[start:end].strip()
            elif "```" in output:
                start = output.find("```") + 3
                end = output.find("```", start)
                if end > start:
                    content = output[start:end].strip()

            json.loads(content)
            return True, None
        except json.JSONDecodeError as e:
            return False, f"Invalid JSON: {e}"

    @staticmethod
    def python_syntax(output: str) -> tuple[bool, str | None]:
        """Check output is valid Python syntax."""
        try:
            # Extract code from markdown blocks
            content = output
            if "```python" in output:
                start = output.find("```python") + 9
                end = output.find("```", start)
                if end > start:
                    content = output[start:end].strip()
            elif "```" in output:
                start = output.find("```") + 3
                end = output.find("```", start)
                if end > start:
                    content = output[start:end].strip()

            ast.parse(content)
            return True, None
        except SyntaxError as e:
            return False, f"Syntax error: {e}"

    @staticmethod
    def contains_keys(output: str, keys: list[str]) -> tuple[bool, str | None]:
        """Check JSON output contains required keys."""
        valid, error = Validator.json_valid(output)
        if not valid:
            return valid, error

        try:
            # Extract JSON content
            content = output
            if "```json" in output:
                start = output.find("```json") + 7
                end = output.find("```", start)
                if end > start:
                    content = output[start:end].strip()

            data = json.loads(content)
            missing = [k for k in keys if k not in data]
            if missing:
                return False, f"Missing keys: {missing}"
            return True, None
        except (json.JSONDecodeError, TypeError) as e:
            return False, f"JSON parse error: {e}"


# === Step Executor ===


class StepExecutor:
    """Executes individual plan steps."""

    def __init__(self, lm_client: LMStudioClient, project_root: Path | None = None):
        self.lm_client = lm_client
        self.project_root = project_root
        self.context_accumulator: dict[int, str] = {}

    def load_file_context(self, files_context: dict[str, str]) -> str:
        """Load file contents for context injection."""
        if not self.project_root or not files_context:
            return ""

        context_parts = []
        for file_path, load_type in files_context.items():
            full_path = self.project_root / file_path
            if load_type == "LOAD" and full_path.exists():
                try:
                    content = full_path.read_text()
                    context_parts.append(f"=== {file_path} ===\n{content}")
                except Exception as e:
                    context_parts.append(f"=== {file_path} ===\n[Error loading: {e}]")
            elif load_type == "REFERENCE":
                context_parts.append(f"=== {file_path} ===\n[File reference only]")

        return "\n\n".join(context_parts)

    def build_prompt(self, step: dict[str, Any], file_context: str) -> str:
        """Build complete prompt with context."""
        parts = []

        # Add file context if available
        if file_context:
            parts.append("## File Context\n" + file_context)

        # Add results from dependencies
        depends_on = step.get("depends_on", [])
        if depends_on:
            dep_context = []
            for dep_id in depends_on:
                if dep_id in self.context_accumulator:
                    dep_context.append(
                        f"## Result from Step {dep_id}\n{self.context_accumulator[dep_id]}"
                    )
            if dep_context:
                parts.append("\n\n".join(dep_context))

        # Add the actual prompt
        parts.append("## Task\n" + step["prompt"])

        return "\n\n".join(parts)

    def execute(
        self, step: dict[str, Any], file_context: str
    ) -> StepResult:
        """Execute a single step with retries."""
        step_id = step["id"]
        max_retries = step.get("max_retries", 2)
        on_failure = step.get("on_failure", "retry_with_context")
        validation = step.get("validation", {"type": "non_empty"})

        prompt = self.build_prompt(step, file_context)
        retries = 0
        last_error = None

        while retries <= max_retries:
            try:
                log.info(f"Step {step_id}: Executing (attempt {retries + 1})")
                output = self.lm_client.generate(prompt)

                # Validate output
                valid, error = Validator.validate(output, validation)
                if valid:
                    # Store in accumulator for dependent steps
                    self.context_accumulator[step_id] = output

                    # Write file if specified
                    file_output = step.get("file_output")
                    if file_output and self.project_root:
                        self._write_output(file_output, output)

                    log.info(f"Step {step_id}: Success")
                    return StepResult(
                        step_id=step_id,
                        success=True,
                        output=output,
                        retries=retries,
                    )

                last_error = error
                log.warning(f"Step {step_id}: Validation failed - {error}")

                if on_failure == "retry_with_context" and retries < max_retries:
                    # Add error context to prompt for retry
                    prompt += f"\n\n## Previous Attempt Failed\nError: {error}\nPlease fix and try again."
                    retries += 1
                elif on_failure == "skip":
                    return StepResult(
                        step_id=step_id,
                        success=False,
                        output=output,
                        error=f"Skipped after validation failure: {error}",
                    )
                else:
                    break

            except httpx.RequestError as e:
                last_error = str(e)
                log.error(f"Step {step_id}: Request error - {e}")
                retries += 1

        return StepResult(
            step_id=step_id,
            success=False,
            output="",
            error=last_error,
            retries=retries,
        )

    def _write_output(self, file_path: str, output: str) -> None:
        """Write step output to file."""
        if not self.project_root:
            return

        full_path = self.project_root / file_path

        # Extract code from markdown blocks
        content = output
        if "```python" in output:
            start = output.find("```python") + 9
            end = output.find("```", start)
            if end > start:
                content = output[start:end].strip()
        elif "```" in output:
            start = output.find("```") + 3
            # Skip language identifier if present
            newline = output.find("\n", start)
            if newline > start:
                start = newline + 1
            end = output.find("```", start)
            if end > start:
                content = output[start:end].strip()

        # Create parent directories
        full_path.parent.mkdir(parents=True, exist_ok=True)

        # Backup existing file
        if full_path.exists():
            backup = full_path.with_suffix(full_path.suffix + ".bak")
            shutil.copy2(full_path, backup)

        full_path.write_text(content)
        log.info(f"Wrote output to {file_path}")


# === Plan Executor ===


class PlanExecutor:
    """Executes complete plans."""

    def __init__(self, reader: DoobidooReader, lm_client: LMStudioClient):
        self.reader = reader
        self.lm_client = lm_client

    def execute(self, plan_data: dict[str, Any]) -> PlanResult:
        """Execute a complete plan."""
        db_id = plan_data["db_id"]
        plan = plan_data["plan"]
        plan_id = plan["id"]

        log.info(f"Executing plan: {plan_id}")
        log.info(f"Objective: {plan['context'].get('objective', 'N/A')}")

        # Update status to in_progress
        self.reader.update_plan_status(db_id, "in_progress")

        # Setup executor
        project_root = None
        if project_path := plan["context"].get("project"):
            project_root = Path(project_path)
            if not project_root.exists():
                log.warning(f"Project root does not exist: {project_root}")
                project_root = None

        step_executor = StepExecutor(self.lm_client, project_root)

        # Load file context
        files_context = plan["context"].get("files_context", {})
        file_context = step_executor.load_file_context(files_context)

        # Track step results
        results: list[StepResult] = []
        failed_steps: set[int] = set()

        # Execute steps in order
        for step in plan["steps"]:
            step_id = step["id"]

            # Check dependencies
            depends_on = step.get("depends_on", [])
            if any(dep in failed_steps for dep in depends_on):
                log.warning(f"Step {step_id}: Skipping due to failed dependency")
                results.append(
                    StepResult(
                        step_id=step_id,
                        success=False,
                        output="",
                        error="Skipped: dependency failed",
                    )
                )
                failed_steps.add(step_id)
                continue

            # Execute step
            result = step_executor.execute(step, file_context)
            results.append(result)

            if not result.success:
                failed_steps.add(step_id)
                on_failure = step.get("on_failure", "retry_with_context")
                if on_failure == "halt":
                    log.error(f"Step {step_id} failed with halt policy - stopping plan")
                    break

        # Determine overall success
        success = all(r.success for r in results)

        # Handle rollback if needed
        if not success and plan.get("rollback_strategy") == "revert_files":
            self._rollback(project_root, plan["steps"])

        # Update final status
        final_status = "completed" if success else "failed"
        self.reader.update_plan_status(db_id, final_status)

        # Create result
        plan_result = PlanResult(
            plan_id=plan_id,
            success=success,
            steps=results,
            error=None if success else "One or more steps failed",
        )

        # Store result
        self.reader.store_result(plan_id, plan_result)

        log.info(f"Plan {plan_id}: {'Completed successfully' if success else 'Failed'}")
        return plan_result

    def _rollback(self, project_root: Path | None, steps: list[dict]) -> None:
        """Rollback file changes by restoring backups."""
        if not project_root:
            return

        log.info("Rolling back file changes...")
        for step in steps:
            if file_output := step.get("file_output"):
                backup = project_root / (file_output + ".bak")
                original = project_root / file_output
                if backup.exists():
                    shutil.move(str(backup), str(original))
                    log.info(f"Restored {file_output}")


# === CLI ===


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Bridge: Claude Code → doobidoo → LM Studio"
    )
    parser.add_argument("--list", action="store_true", help="List pending plans")
    parser.add_argument("--plan", type=str, help="Execute specific plan by ID")
    parser.add_argument("--health", action="store_true", help="Check LM Studio health")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")

    args = parser.parse_args()

    if args.verbose:
        log.setLevel(logging.DEBUG)

    # Health check
    if args.health:
        client = LMStudioClient()
        if client.health_check():
            print("LM Studio: OK (running at localhost:1234)")
            client.close()
            return 0
        else:
            print("LM Studio: NOT RUNNING")
            print("Start LM Studio and load a model first.")
            client.close()
            return 1

    # Check doobidoo database
    try:
        reader = DoobidooReader()
    except FileNotFoundError as e:
        print(f"Error: {e}")
        print("Ensure doobidoo MCP server has been used at least once.")
        return 1

    # List plans
    if args.list:
        plans = reader.get_pending_plans()
        if not plans:
            print("No pending plans found.")
            return 0

        print(f"Found {len(plans)} pending plan(s):\n")
        for p in plans:
            plan = p["plan"]
            print(f"  ID: {plan['id']}")
            print(f"  Objective: {plan['context'].get('objective', 'N/A')}")
            print(f"  Steps: {len(plan['steps'])}")
            print(f"  Created: {p['created_at']}")
            print()
        return 0

    # Check LM Studio
    lm_client = LMStudioClient()
    if not lm_client.health_check():
        print("Error: LM Studio is not running at localhost:1234")
        print("Start LM Studio and load a model first.")
        lm_client.close()
        return 1

    executor = PlanExecutor(reader, lm_client)

    # Execute specific plan
    if args.plan:
        plan_data = reader.get_plan_by_id(args.plan)
        if not plan_data:
            print(f"Plan not found: {args.plan}")
            lm_client.close()
            return 1

        result = executor.execute(plan_data)
        lm_client.close()
        return 0 if result.success else 1

    # Execute all pending plans
    plans = reader.get_pending_plans()
    if not plans:
        print("No pending plans to execute.")
        lm_client.close()
        return 0

    print(f"Executing {len(plans)} pending plan(s)...\n")
    all_success = True

    for plan_data in plans:
        result = executor.execute(plan_data)
        if not result.success:
            all_success = False
        print()

    lm_client.close()
    return 0 if all_success else 1


if __name__ == "__main__":
    sys.exit(main())
