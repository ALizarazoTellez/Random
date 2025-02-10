# Lang Script

This is a great example of **how not to program in Lua**.

This script extracts audio and subtitles from the current stream. It requires `ffmpeg`.

It was created to help me learn English.

It needs to follow clean and good practices (such as using a `.conf` file for configuration).

### Bindings:

- `Up`: Repeat the current subtitle.
- `Down`: Toggle subtitles.
- `Left`: Jump to the previous subtitle.
- `Right`: Play (you can spam it, as it does not pause).
- `Enter`: Extract audio and subtitles (remember to modify the script to change the directory; the variable is `save_directory`).

The script automatically pauses at the start of each subtitle, but the bindings assume it's the end of the previous one. Did I already mention that this needs to be cleaned up?
