import json
import re


def _fix_json_control_chars(text: str) -> str:
    """Escape literal control characters that appear inside JSON string values.

    Gemini occasionally emits raw newlines / tabs inside string values instead
    of the \\n / \\t escape sequences, producing invalid JSON.  This scanner
    walks the text character-by-character, tracking whether we are inside a
    quoted string, and replaces any bare control character it finds there.
    """
    result = []
    in_string = False
    i = 0
    while i < len(text):
        ch = text[i]
        if in_string:
            if ch == '\\' and i + 1 < len(text):
                result.append(ch)
                result.append(text[i + 1])
                i += 2
                continue
            elif ch == '"':
                result.append(ch)
                in_string = False
            elif ch == '\n':
                result.append('\\n')
            elif ch == '\r':
                result.append('\\r')
            elif ch == '\t':
                result.append('\\t')
            else:
                result.append(ch)
        else:
            if ch == '"':
                in_string = True
            result.append(ch)
        i += 1
    return ''.join(result)


def parse_gemini_response(response) -> dict:
    if hasattr(response, 'parsed') and response.parsed is not None:
        parsed = response.parsed
        return parsed.model_dump() if hasattr(parsed, 'model_dump') else parsed
    text = response.text.strip()
    fence_match = re.search(r'```(?:json)?\s*([\s\S]*?)\s*```', text)
    if fence_match:
        text = fence_match.group(1).strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return json.loads(_fix_json_control_chars(text))
