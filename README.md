# 67 (Modern file encoding)

A modern and sleek URL-safe encoding system for arbitrary data. this tool comes
packaged with an encoder and decoder.

## How does it work

67 works by taking a file and generating code to recreate each byte using a
stack based virtual machine. The instructions for this machine are then
converted into a sequence of 6s and 7s based on where they occur in a prefix
tree. The tree used (as of now) is below:

```
_
+- 6
|  +- 6 (Push 6) [6]
|  +- 7 (Push 7) [7]
|
+- 7
   +- 6
   |  +- 6
   |  |  +- 6 (Add) [+]
   |  |  +- 7 (Subtract) [-]
   |  |
   |  +- 7
   |     +- 6 (Multiply) [*]
   |     +- 7 (End Of File) [!]
   |
   +- 7 (Output) [.]
``` 

This is done to maximise the amount of 6s and 7s produced. It makes instructions
appear within other instructions, forcing the entire file to be parsed in order.
Each line in the graph above that has a `[...]` at the end is an opcode, and the
brackets have the Assembly/textual form of the opcode. We call this easier form
"internal 67".

When parsing an instruction, you start at the root and descend down either the 6
branch or 7 branch based on what you get next.

The binary operators (`+-*`) pop the top two elements and perform the operation,
and then push the result. For example, running `+` on the stack `[..., 6, 7]`
pushes the result of `6 + 7` onto the stack, resulting in the stack looking like
`[..., 13]`. The output instruction `.` pops a value from the stack and writes
it to the output file.

The stack is an array of unsigned bytes. Each of the binary operations wrap
around on overflow. So an operation like `6 - 7` results in `255`. This feature
can be relied on as a valid 67 decoder must support this wraparound approach.

## Simple example

Code for writing `A`(ascii 65/#41) looks like this in 67
```
67676676677666677666676766766776666776667676676676677666777677
```

and like this with internal 67.

```
776-+7+776-+7+*76-+.!
```

## TODO

- [X] Encoder
- [X] Decoder
- [ ] Understandable system
    - [ ] make the code more DRY
    - [ ] seperate internal format from 67 representation
- [ ] Explain it better
    - [X] explain internal code model
    - [X] explain the greedy-prefixing format
    - [ ] you should really not take this seriously
    - [X] Demos and stuff

