# goal

- [command](#command)
- [goal](#goal-1)

## command

- backspace erase `](https://example.com)` when erase from underline?

```
[example](https://exmaple.com)
<cursor>
```

current behavior:
```
[example<cursor>
```

what i want
```
[example](https://exmaple.com)<cursor>
```

## goal

When Backspace removes the line break immediately after a Markdown link in the note editor, preserve the complete link and place the cursor after it.
