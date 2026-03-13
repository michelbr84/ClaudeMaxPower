"""
Tests for todo.py.

Some tests here are designed to FAIL against the buggy implementation.
They will pass once the fix-issue skill corrects the bugs.
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

import pytest
from todo import Task, TodoList


class TestAddTask:
    def test_add_single_task(self):
        tl = TodoList()
        task = tl.add_task("Buy milk")
        assert task.title == "Buy milk"
        assert task.id == 1
        assert task.done is False
        assert len(tl.tasks) == 1

    def test_add_multiple_tasks(self):
        tl = TodoList()
        t1 = tl.add_task("Task A")
        t2 = tl.add_task("Task B")
        assert t1.id == 1
        assert t2.id == 2
        assert len(tl.tasks) == 2

    def test_add_task_with_priority(self):
        tl = TodoList()
        task = tl.add_task("Urgent task", priority=10)
        assert task.priority == 10


class TestDeleteTask:
    def test_delete_first_task(self):
        tl = TodoList()
        t1 = tl.add_task("Task 1")
        result = tl.delete_task(t1.id)
        assert result is True
        assert len(tl.tasks) == 0

    def test_delete_second_task(self):
        """BUG #1: This test exposes the off-by-one error."""
        tl = TodoList()
        t1 = tl.add_task("Task 1")
        t2 = tl.add_task("Task 2")
        result = tl.delete_task(t2.id)
        assert result is True
        # After deleting task 2, only task 1 should remain
        assert len(tl.tasks) == 1
        assert tl.tasks[0].id == t1.id

    def test_delete_nonexistent_task(self):
        tl = TodoList()
        tl.add_task("Task 1")
        result = tl.delete_task(999)
        assert result is False
        assert len(tl.tasks) == 1


class TestCompleteTask:
    def test_complete_correct_task(self):
        """BUG #2: This test exposes the always-marks-first-task bug."""
        tl = TodoList()
        t1 = tl.add_task("Task 1")
        t2 = tl.add_task("Task 2")

        result = tl.complete_task(t2.id)
        assert result is True
        assert t1.done is False   # Task 1 should NOT be marked done
        assert t2.done is True    # Task 2 SHOULD be marked done

    def test_complete_nonexistent_task(self):
        tl = TodoList()
        tl.add_task("Task 1")
        result = tl.complete_task(999)
        assert result is False


class TestListTasks:
    def test_list_sorted_by_priority_highest_first(self):
        """BUG #3: This test exposes the wrong sort direction."""
        tl = TodoList()
        tl.add_task("Low priority", priority=1)
        tl.add_task("High priority", priority=10)
        tl.add_task("Medium priority", priority=5)

        tasks = tl.list_tasks()
        priorities = [t.priority for t in tasks]
        assert priorities == [10, 5, 1], f"Expected [10, 5, 1] but got {priorities}"

    def test_list_excludes_done_by_default(self):
        tl = TodoList()
        t1 = tl.add_task("Active task")
        t2 = tl.add_task("Done task")
        t2.done = True

        tasks = tl.list_tasks()
        assert len(tasks) == 1
        assert tasks[0].id == t1.id

    def test_list_includes_done_when_requested(self):
        tl = TodoList()
        t1 = tl.add_task("Active")
        t2 = tl.add_task("Done")
        t2.done = True

        tasks = tl.list_tasks(show_done=True)
        assert len(tasks) == 2


class TestGetTask:
    def test_get_existing_task(self):
        tl = TodoList()
        t1 = tl.add_task("Task 1")
        found = tl.get_task(t1.id)
        assert found is not None
        assert found.id == t1.id

    def test_get_nonexistent_task(self):
        tl = TodoList()
        found = tl.get_task(999)
        assert found is None
