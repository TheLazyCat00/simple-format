# simple-format

simple-format allows you to search and replace with highlight groups + regex, making it easy to create custom formatting rules.
I created this plugin because I wanted a formatter that does not change the whole styling of my code but only removes unnecessary white space.

https://github.com/user-attachments/assets/600ed7a0-98ae-48b4-925f-b7dc9ac01fb9

## Installation with [lazy.nvim](https://github.com/folke/lazy.nvim)

simple-format does not automatically format on save. Instead, simple-format provides a `replace` function, which can be called when needed. This allows everybody to have their own formatting logic.

> [!NOTE]
> The `replace` function only modifies the line under the cursor.

```lua
{
    "TheLazyCat00/simple-format",
    opts = {
        -- the anchors for search and replace
        -- use uncommon characters or sequences
        injectionOpeningAnchor = "\226\160\128",
        injectionClosingAnchor = "\226\160\129",

        -- the opening and closing tags for the search syntax
        groupStart = "<",
        groupEnd = ">",
    },
    config = function (_, opts)
        local replace = require("simple-format").replace
        replace.setup(opts)

        -- add your own formatting logic
        -- remember to use vim.schedule to prevent neovim from freezing briefly
    end
}
```

You can also also use the `reveal` function to inspect the line and see what you need to search for (shown later in my personal config).

<details>
<summary>Defaults</summary>

```lua
{
    -- HACK: use uncommon characters as anchors
    injectionOpeningAnchor = "\226\160\128",
    injectionClosingAnchor = "\226\160\129",
    groupStart = "<",
    groupEnd = ">",
}
```
</details>

**My personal config**

With this config, the plugin always formats when I leave insert mode.

```lua
{
    "TheLazyCat00/simple-format",
    event = "BufReadPost",
    opts = {},
    config = function (_, opts)
        local simpleFormat = require("simple-format")
        simpleFormat.setup(opts)
        local replace = simpleFormat.replace
        vim.api.nvim_create_autocmd("InsertLeave", {
            callback = function()
                vim.schedule(function ()
                    -- simpleFormat.reveal() commented out right now, but this shows the line "structure" with vim.notify
                    replace("(%S) -(<.-|operator|.-=.->)", "%1 %2")
                    replace("(<.-|operator|.-=.->) -(%S)", "%1 %2")
                    replace("(<.-|punctuation.delimiter|.-=,>) -(%S)", "%1 %2")
                    replace("(<.-|punctuation.bracket|.-={>) -(<.-|punctuation.bracket|.-=}>)", "%1%2")
                    replace("(<.-|punctuation.bracket|.-={>) -(%S.-%S) -(<.-|punctuation.bracket|.-=}>)", "%1 %2 %3")
                    replace("(<.-|punctuation.bracket|.-=%(>) -(%S.-%S) -(<.-|punctuation.bracket|.-=%)>)", "%1%2%3")
                    replace("(<.-|punctuation.bracket|.-=%(>) -(<.-|punctuation.bracket|.-=%)>)", "%1%2")
                end)
            end,
        })
    end
}
```

## Syntax
The syntax for the search and replace arguments have the same syntax as `str:gsub` in lua.
The only difference is that you can also use highlight groups like `operator` for pattern matching.
The syntax goes: `groupStart + highlightGroups + "=" + desiredValue + groupEnd`.
`highlightGroups` always have `|` on both the left and right side. So if a word is an `operator` and a `punctuation.bracket`
the `highlightGroups` looks like this: `|operator|punctuation.bracket|`. Let's imagine this "word" would be `+`.
In that case the whole "identifier" would look like this:
`<|operator|punctuation.bracket|=+>`

With the defaults you could for example do `<operator=.->`.
This would match any operator. Here we use regex functionality `.-` so that we can match for any operator.
There are great online resources for learning regex, it's not as hard as it looks.
We could also do `<operator==>`. This would match any operator that has `=` as its value.

> [!TIP]
> To see the highlight group under the cursor, do `:Inspect`.

## Examples

These are some useful examples you can use for your own config (assuming you are using the defaults).

- Formatting lists by putting a space after `,`:
  ```lua
  replace("(<.-|punctuation.delimiter|.-=,>) -(%S)", "%1 %2")
  -- Explanation: We wanna search for a punctuation delimiter with
  -- the value ",".
  -- Not that we added .-| and |.- on both sides
  -- so that this works on words with multiple highlight groups
  -- (remember, ".-" matches any string and also empty strings,
  -- so this would work even with only punctuation.delimiter)

  -- We need to capture this, so that we can use the value in the replace process:
  -- We do this by putting it in parentheses.
  -- Then we search for a character that is not a white space:
  -- %S means anything that's NOT a white space character (notice the uppercase S).
  -- We also capture this value for later use.

  -- Then we replace the string with "%1 %2".
  -- This means that we take capture group 1, put a space and add group 2.
  -- NOTE: Groups get labeled automatically in regex according to the order.
  ```
- Removing spaces between arguments and parentheses:
  ```lua
  -- We need to escape parentheses
  replace("(<.-|punctuation.bracket|.-=%(>) -(%S.-%S) -(<.-|punctuation.bracket|.-=%)>)", "%1%2%3")
  replace("(<.-|punctuation.bracket|.-=%(>) -(<.-|punctuation.bracket|.-=%)>)", "%1%2")
  ```

---
Contributions are welcome! Feel free to open issues or submit pull requests.
