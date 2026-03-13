"""
todo.py — A simple CLI todo list manager.

This module contains intentional bugs used to demonstrate ClaudeMaxPower skills.
See CLAUDE.md for the bug list.
"""

from __future__ import annotations
from dataclasses import dataclass, field
from typing import List, Optional


@dataclass
class Task:
    id: int
    title: str
    priority: int = 0
    done: bool = False


@dataclass
class TodoList:
    tasks: List[Task] = field(default_factory=list)
    _next_id: int = 1

    def add_task(self, title: str, priority: int = 0) -> Task:
        """Add a new task and return it."""
        task = Task(id=self._next_id, title=title, priority=priority)
        self.tasks.append(task)
        self._next_id += 1
        return task

    def delete_task(self, task_id: int) -> bool:
        """Delete a task by ID. Returns True if deleted, False if not found.

        BUG #1: Off-by-one error — deletes wrong index when task_id > 1
        """
        for i, task in enumerate(self.tasks):
            if task.id == task_id:
                # BUG: should be self.tasks.pop(i), not self.tasks.pop(i - 1)
                self.tasks.pop(i - 1)
                return True
        return False

    def complete_task(self, task_id: int) -> bool:
        """Mark a task as done. Returns True if found and updated.

        BUG #2: Iterates but always marks the first task, not the matching one
        """
        for task in self.tasks:
            # BUG: should check task.id == task_id before marking done
            task.done = True
            return True
        return False

    def list_tasks(self, show_done: bool = False) -> List[Task]:
        """Return tasks sorted by priority (highest first).

        BUG #3: Sort is ascending instead of descending
        """
        tasks = [t for t in self.tasks if show_done or not t.done]
        # BUG: should be reverse=True for highest-priority-first
        return sorted(tasks, key=lambda t: t.priority)

    def get_task(self, task_id: int) -> Optional[Task]:
        """Return a task by ID, or None if not found."""
        for task in self.tasks:
            if task.id == task_id:
                return task
        return None
