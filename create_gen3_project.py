#!/usr/bin/env python3
"""Manage Gen3 programs and projects via the Sheepdog API."""

import argparse
import json
import logging
import sys

import requests
from gen3.auth import Gen3Auth

logging.basicConfig(
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%H:%M:%S",
    level=logging.INFO,
)
log = logging.getLogger(__name__)


def make_session(endpoint: str, credentials: str | None) -> tuple[requests.Session, str]:
    auth = Gen3Auth(endpoint=endpoint, refresh_file=credentials)
    session = requests.Session()
    session.headers.update({
        "Authorization": f"Bearer {auth.get_access_token()}",
        "Content-Type": "application/json",
    })
    return session, endpoint.rstrip("/")


def cmd_whoami(session: requests.Session, base: str) -> None:
    r = session.get(f"{base}/user/user")
    if not r.ok:
        log.error("HTTP %s: %s", r.status_code, r.text)
        sys.exit(1)
    data = r.json()
    log.info("username:  %s", data.get("username"))
    log.info("is_admin:  %s", data.get("is_admin"))
    log.info("resources: %s", json.dumps(data.get("resources", []), indent=2))


def cmd_list(session: requests.Session, base: str, program: str | None) -> None:
    if program:
        r = session.get(f"{base}/api/v0/submission/{program}/")
        if not r.ok:
            log.error("HTTP %s: %s", r.status_code, r.text)
            sys.exit(1)
        projects = r.json().get("links", [])
        if projects:
            for p in projects:
                log.info("  %s/%s", program, p.lstrip("/").split("/")[-1])
        else:
            log.info("  (no projects)")
    else:
        r = session.get(f"{base}/api/v0/submission/")
        if not r.ok:
            log.error("HTTP %s: %s", r.status_code, r.text)
            sys.exit(1)
        programs = r.json().get("links", [])
        if not programs:
            log.info("No programs found.")
            return
        for prog in programs:
            name = prog.lstrip("/").split("/")[-1]
            log.info("Program: %s", name)
            r2 = session.get(f"{base}/api/v0/submission/{name}/")
            if r2.ok:
                for p in r2.json().get("links", []):
                    log.info("  └─ %s", p.lstrip("/").split("/")[-1])


def cmd_create(session: requests.Session, base: str, program: str, project: str | None) -> None:
    # Program creation: PUT / (root of submission API)
    url = f"{base}/api/v0/submission/"
    log.info("PUT %s", url)
    r = session.put(url, json={"type": "program", "dbgap_accession_number": program, "name": program})
    if r.status_code in (200, 201):
        log.info("✓ program '%s' created", program)
    elif r.status_code == 409:
        log.info("✓ program '%s' already exists", program)
    else:
        log.error("✗ program '%s' — HTTP %s: %s", program, r.status_code, r.text)
        sys.exit(1)

    if project:
        # Project creation: PUT /<program> (one level under program name)
        url = f"{base}/api/v0/submission/{program}/"
        log.info("PUT %s", url)
        r = session.put(url, json={
            "type": "project", "code": project, "name": project,
            "dbgap_accession_number": project, "state": "open",
        })
        if r.status_code in (200, 201):
            log.info("✓ project '%s/%s' created", program, project)
        elif r.status_code == 409:
            log.info("✓ project '%s/%s' already exists", program, project)
        else:
            log.error("✗ project '%s/%s' — HTTP %s: %s", program, project, r.status_code, r.text)
            sys.exit(1)


def cmd_delete(session: requests.Session, base: str, program: str, project: str | None) -> None:
    if project:
        url = f"{base}/api/v0/submission/{program}/{project}"
        log.info("DELETE %s", url)
        r = session.delete(url)
        if r.ok:
            log.info("✓ project '%s/%s' deleted", program, project)
        else:
            log.error("✗ HTTP %s: %s", r.status_code, r.text)
            sys.exit(1)
    else:
        url = f"{base}/api/v0/submission/{program}"
        log.info("DELETE %s", url)
        r = session.delete(url)
        if r.ok:
            log.info("✓ program '%s' deleted", program)
        else:
            log.error("✗ HTTP %s: %s", r.status_code, r.text)
            sys.exit(1)


def main() -> None:
    parser = argparse.ArgumentParser(description="Manage Gen3 programs and projects.")
    parser.add_argument("--endpoint", required=True, help="Gen3 commons URL")
    parser.add_argument("--credentials", default=None, help="Path to credentials JSON (default: ~/.gen3/credentials.json)")

    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("whoami", help="Show current user info and admin status")

    p_list = sub.add_parser("list", help="List programs (and projects within a program)")
    p_list.add_argument("--program", help="Program name to list projects for")

    p_create = sub.add_parser("create", help="Create a program and optionally a project")
    p_create.add_argument("--program", required=True)
    p_create.add_argument("--project")

    p_delete = sub.add_parser("delete", help="Delete a program or project")
    p_delete.add_argument("--program", required=True)
    p_delete.add_argument("--project", help="Omit to delete the entire program")

    args = parser.parse_args()
    session, base = make_session(args.endpoint, args.credentials)

    if args.command == "whoami":
        cmd_whoami(session, base)
    elif args.command == "list":
        cmd_list(session, base, getattr(args, "program", None))
    elif args.command == "create":
        cmd_create(session, base, args.program, args.project)
    elif args.command == "delete":
        cmd_delete(session, base, args.program, args.project)


if __name__ == "__main__":
    main()
