# simple-format

simple-format allows you to search and replace with highlight groups + regex, making it easy to create custom formatting rules.
I created this plugin because I wanted a formatter that does change the whole styling of my code but only removes unnecessary white space.

## Installation with [lazy.nvim](https://github.com/folke/lazy.nvim)

simple-format does not automatically format on save. Instead, simple-format provides a `replace` function, which can be used for the formatting. This allows everybody to have their own formatting logic.

> [!NOTE]
> The `replace` function only modifies the line under the cursor.

```lua
{
    "TheLazyCat00/simple-format",
    opts = {
        -- the anchors for search and replace
        -- use uncommon characters or sequences
        opening_anchor = "\226\160\128",
        closing_anchor = "\226\160\129",

        -- the opening and closing tags for the search syntax
        group_start = "<",
        group_end = ">",
    },
    config = function ()
        local replace = require("simple-format").replace

        -- add your own formatting logic
        -- remember to use vim.schedule to prevent blocking the user
    end
}
```

<details>
<summary>Defaults</summary>

```lua
{
    -- HACK: use uncommon characters as anchors
    opening_anchor = "\226\160\128",
    closing_anchor = "\226\160\129",
    group_start = "<",
    group_end = ">",
}
```
</details>

### My personal config

With this config, the plugin always formats when I leave insert mode.

```lua
{
    "TheLazyCat00/simple-format",
    event = "BufReadPost",
    opts = {},
    config = function ()
        vim.api.nvim_create_autocmd("InsertLeave", {
            callback = function()
                vim.schedule(function ()
                    local replace = require("simple-format").replace
                    replace("(%S)(<operator>)", "%1 %2")
                    replace("(<operator>)(%S)", "%1 %2")
                    replace("(%S)(<constructor>)", "%1 %2")
                    replace("(<constructor>)(%S)", "%1 %2")
                    replace("(<constructor>) (<punctuation.bracket>)", "%1%2")
                    replace("(<punctuation.bracket>) (<constructor>)", "%1%2")
                    replace("(<constructor>) (<punctuation.delimiter>)", "%1%2")
                end)
            end,
        })
    end
}
```

## Syntax
The syntax for the search and replace arguments have the same syntax as `str:gsub` in lua.
The only difference is that you can also use highlight groups like `operator` for pattern matching.
Just make sure that you put the highlight group in between the tags you chose in the opts.
With the defaults it would be `<operator>`.

---
Contributions are welcome! Feel free to open issues or submit pull requests.
