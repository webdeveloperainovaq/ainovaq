"""python -m ainovaq: a tiny command line for the SDK."""

import json
import sys

from . import Ainovaq, AinovaqError, __version__

USAGE = """ainovaq %s
  python -m ainovaq services
  python -m ainovaq service <build|gtm|digital|talent|infra>
  python -m ainovaq search <words>
  python -m ainovaq contact""" % __version__


def main() -> int:
    args = sys.argv[1:]
    if not args or args[0] in ("-h", "--help", "help"):
        print(USAGE)
        return 0
    client = Ainovaq()
    cmd, rest = args[0], args[1:]
    try:
        if cmd == "services":
            data = client.services()
        elif cmd == "service" and rest:
            data = client.service(rest[0])
        elif cmd == "search" and rest:
            data = client.search_articles(" ".join(rest))
        elif cmd == "contact":
            data = client.contact()
        else:
            print(USAGE, file=sys.stderr)
            return 2
    except AinovaqError as e:
        print("ainovaq: %s" % e, file=sys.stderr)
        return 1
    print(json.dumps(data, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
