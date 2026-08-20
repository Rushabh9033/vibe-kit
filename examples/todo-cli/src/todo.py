#!/usr/bin/env python3
"""todo-cli — minimal single-user todo list.

Storage: ./todos.json (JSON array).
Commands:
    todo add <text>     — append; assign sequential id
    todo list           — print open todos
    todo done <id>      — mark complete
    todo rm <id>        — delete
    todo help           — print usage

Exit codes:
    0 success
    1 unknown subcommand
    2 missing argument
    3 unknown todo id
"""
import json
import os
import sys
from pathlib import Path

STORE = Path(os.environ.get("TODO_CLI_STORE", "todos.json"))


def _load():
    if not STORE.exists():
        return []
    try:
        with STORE.open() as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        print(f"warning: corrupt store ({e}); treating as empty", file=sys.stderr)
        return []


def _save(todos):
    tmp = STORE.with_suffix(".tmp")
    with tmp.open("w") as f:
        json.dump(todos, f, indent=2)
    tmp.replace(STORE)


def _next_id(todos):
    return (max((t["id"] for t in todos), default=0)) + 1


def cmd_add(args):
    if not args:
        print("usage: todo add <text>", file=sys.stderr)
        return 2
    text = " ".join(args)
    todos = _load()
    tid = _next_id(todos)
    todos.append({"id": tid, "text": text, "done": False})
    _save(todos)
    print(tid)
    return 0


def cmd_list(_args):
    todos = _load()
    for t in todos:
        if not t.get("done"):
            print(f"{t['id']}\t{t['text']}")
    return 0


def cmd_done(args):
    if not args:
        print("usage: todo done <id>", file=sys.stderr)
        return 2
    try:
        tid = int(args[0])
    except ValueError:
        print(f"todo: id must be integer, got {args[0]!r}", file=sys.stderr)
        return 3
    todos = _load()
    for t in todos:
        if t["id"] == tid:
            t["done"] = True
            _save(todos)
            return 0
    print(f"todo: no such id {tid}", file=sys.stderr)
    return 3


def cmd_rm(args):
    if not args:
        print("usage: todo rm <id>", file=sys.stderr)
        return 2
    try:
        tid = int(args[0])
    except ValueError:
        print(f"todo: id must be integer, got {args[0]!r}", file=sys.stderr)
        return 3
    todos = _load()
    kept = [t for t in todos if t["id"] != tid]
    if len(kept) == len(todos):
        print(f"todo: no such id {tid}", file=sys.stderr)
        return 3
    _save(kept)
    return 0


USAGE = """usage: todo <command> [args]

commands:
    add <text>     add a todo
    list           list open todos
    done <id>      mark complete
    rm <id>        delete
    help           show this help
"""


def main(argv=None):
    argv = argv if argv is not None else sys.argv[1:]
    if not argv or argv[0] in ("help", "-h", "--help"):
        print(USAGE)
        return 0
    cmd, args = argv[0], argv[1:]
    dispatch = {
        "add": cmd_add,
        "list": cmd_list,
        "done": cmd_done,
        "rm": cmd_rm,
    }
    fn = dispatch.get(cmd)
    if fn is None:
        print(USAGE, file=sys.stderr)
        print(f"todo: unknown command {cmd!r}", file=sys.stderr)
        return 1
    return fn(args)


if __name__ == "__main__":
    sys.exit(main())
