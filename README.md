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
    config = function (_, opts)
        local replace = require("simple-format").replace
        replace.setup(opts)

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

**My personal config**

With this config, the plugin always formats when I leave insert mode.

```lua
{
    "TheLazyCat00/simple-format",
    event = "BufReadPost",
    -- enabled = false,
    opts = {},
    config = function (_, opts)
        local simple_format = require("simple-format")
        simple_format.setup(opts)
        local replace = simple_format.replace
        vim.api.nvim_create_autocmd("InsertLeave", {
            callback = function()
                vim.schedule(function ()
                    replace("(%S)(<operator=.->)", "%1 %2")
                    replace("(<operator=.->)(%S)", "%1 %2")
                    replace("(<punctuation.delimiter=,>)(%S)", "%1 %2")
                    replace("(<punctuation.bracket={>)(%S)", "%1 %2")
                    replace("(%S)(<punctuation.bracket=}>)", "%1 %2")
                    replace("(<punctuation.bracket=.->) (<punctuation.bracket=.->)", "%1%2")
                end)
            end,
        })
    end
}
```

## Syntax
The syntax for the search and replace arguments have the same syntax as `str:gsub` in lua.
The only difference is that you can also use highlight groups like `operator` for pattern matching.
The syntax goes: `group_start + highlight_group + "=" + desired_value + group_end`.
Just make sure that you put the highlight group in between the tags you chose in the opts.
You also have to specify the value of the highlight group.
With the defaults you could for example do `<operator=.->`.
This would match any operator. Here we use regex functionality `.-` so that we can match for any string.
There are great online resources for learning regex, it's not as hard as it looks.
We could also do `<operator==>`. This would match any operator that has `=` as its value.

> [!TIP]
> To see the highlight group under the cursor, do `:Inspect`.

## Examples

These are some useful examples you can use for your own config (assuming you are using the defaults).

- Formatting lists by putting a space after `,`:
    ```lua
    replace("(<punctuation.delimiter=,>)(%S)", "%1 %2")
    -- Explanation: We wanna search for a punctuation delimiter with
    -- the value ",".
    -- We need to capture this, so that we can use the value in the replace process:
    -- We do this putting it in parentheses.
    -- Then we search for a character that is not a white space:
    -- %S means anything thats NOT a white space character.
    -- We also capture this value for later use.

    -- Then we replace the string with "%1 %2".
    -- This means that we take capture group 1, put a space and add group 2.
    -- NOTE: Groups get labeled automatically in regex according to the order.
    ```
- Removing spaces between arguments and parentheses:
    ```lua
	-- We need to escape parentheses
    replace("<punctuation.bracket=%(> ", "(")
    replace(" <punctuation.bracket=%)>", ")")
    ```

---
Contributions are welcome! Feel free to open issues or submit pull requests.
