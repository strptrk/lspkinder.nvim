local symbol_preset = {
  -- {{{ Text
  Text = "",
  String = "",
  StringRegex = "󰑑",
  StringEscape = "󱔁",
  PunctuationSpecial = "",
  Character = "",
  Comment = "󰆉",
  Spell = "󰓆",
  Nospell = "󰓆",
  -- }}}
  -- {{{ Programming keyword
  Symbol = "󱄑",
  Storageclass = "",
  Method = "",
  Function = "",
  FunctionKeyword = "",
  KeywordFunction = "",
  FunctionCall = "",
  Constructor = "",
  Field = "ﰠ",
  Class = "ﴯ",
  _Parent = "ﴯ",
  Interface = "",
  Module = "",
  Property = "ﰠ",
  FunctionMacro = "",
  Repeat = "󰑖",
  Error = "",
  None = "",
  Enum = "",
  Conditional = "",
  Keyword = "",
  KeywordReturn = "󰌑",
  Namespace = "",
  Reference = "",
  Operator = "",
  KeywordOperator = "",
  Define = "",
  Include = "󰼢",
  Struct = "פּ",
  TypeQualifier = "󰉺",
  Event = "",
  -- }}}
  -- {{{ Variable types
  Unit = "塞",
  Variable = "",
  Type = "",
  Boolean = "",
  TypeBuiltin = "",
  Value = "",
  Number = "",
  Constant = "",
  ConstantBuiltin = "",
  EnumMember = "",
  TypeParameter = "",
  Parameter = "",
  -- }}}
  -- {{{ Misc
  Snippet = "",
  Color = "",
  File = "",
  Folder = "",
  Conceal = "󰰀",
  -- }}}
  -- {{{ Markdown items
  NeorgHeadings1Title = "󰉫",
  NeorgHeadings2Title = "󰉬",
  NeorgHeadings3Title = "󰉭",
  NeorgHeadings4Title = "󰉮",
  NeorgHeadings5Title = "󰉯",
  NeorgHeadings6Title = "󰉰",
  NeorgHeadings1Prefix = "󰉫",
  NeorgHeadings2Prefix = "󰉬",
  NeorgHeadings3Prefix = "󰉭",
  NeorgHeadings4Prefix = "󰉮",
  NeorgHeadings5Prefix = "󰉯",
  NeorgHeadings6Prefix = "󰉰",
  NeorgListsUnorderedPrefix = "",
  NeorgLinksLocationDelimiter = "",
  NeorgAnchorsDefinitionDelimiter = "",
  NeorgAnchorsDeclaration = "",
  NeorgAnchors = "",
  NeorgLinksLocationUrl = "",
  TextTitle1 = "󰉫",
  TextTitle2 = "󰉬",
  TextTitle3 = "󰉭",
  TextTitle4 = "󰉮",
  TextTitle5 = "󰉯",
  TextTitle6 = "󰉰",
  TextUri = "",
  TextReference = "",
  TextEnvironment = "󰅩",
  TextEnvironmentName = "󰅩",
  TextEmphasis = "",
  TextStrong = "",
  -- }}}
  unknown = ""
}

local kind_order = {
  "Text",
  "Method",
  "Function",
  "Constructor",
  "Field",
  "Variable",
  "Class",
  "Interface",
  "Module",
  "Property",
  "Unit",
  "Value",
  "Enum",
  "Keyword",
  "Snippet",
  "Color",
  "File",
  "Reference",
  "Folder",
  "EnumMember",
  "Constant",
  "Struct",
  "Event",
  "Operator",
  "TypeParameter",
}

local lspkind = {}

local misses = {}

local function dump_misses()
  local misses_list = {}
  for k, _ in pairs(misses) do
    table.insert(misses_list, k)
  end
  local json = vim.json.encode(misses_list)
  local timestamp = vim.fn.strftime("%F-%T")
  local filename = "/tmp/" .. os.getenv('USER') .. "_lspkind_misses_" .. timestamp .. ".json"
  local file = io.open(filename, 'w')
  if file then
    file:write(tostring(json))
    file:close()
  else
    vim.notify("dump_misses file open failed", vim.log.levels.ERROR)
  end
end
local function show_misses()
  local misses_list = {}
  for k, _ in pairs(misses) do
    table.insert(misses_list, k)
  end
  vim.notify(vim.inspect(misses_list), vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("DumpCompletionMisses", dump_misses, { nargs = 0 })
vim.api.nvim_create_user_command("ShowCompletionMisses", show_misses, { nargs = 0 })

local function heuristic(symbol)
  if misses[symbol] == nil then
    misses[symbol] = true
  end
  -- TODO: do the regex-based heuristic
  return symbol_preset.unknown
end

-- needed for some of the unknown symbols that come up time to time
local function get_symbol(symbol)
  return lspkind.symbol_map[symbol] or heuristic(symbol)
end

function lspkind.symbolic(kind, _)
  return string.format("%s %s", get_symbol(kind), kind)
end

lspkind.symbol_map = nil

function lspkind.setup(opts)
  if not opts then opts = {} end
  lspkind.symbol_map = vim.tbl_extend("force", symbol_preset, opts["symbol_map"])
  local symbols = {}
  for i = 1, #kind_order do
    local name = kind_order[i]
    symbols[i] = lspkind.symbolic(name, opts)
  end
  for k, v in pairs(symbols) do
    require("vim.lsp.protocol").CompletionItemKind[k] = v
  end
end


function lspkind.cmp_format(opts)
  if opts == nil then
    opts = {}
  end
  if lspkind.symbol_map == nil and opts.preset or opts.symbol_map then
    lspkind.setup(opts)
  end

  return function(entry, vim_item)
    if opts.before then
      vim_item = opts.before(entry, vim_item)
    end

    vim_item.kind = lspkind.symbolic(vim_item.kind, opts)

    if opts.menu ~= nil then
      vim_item.menu = (opts.menu[entry.source.name] ~= nil and opts.menu[entry.source.name] or "")
        .. ((opts.show_labelDetails and vim_item.menu ~= nil) and vim_item.menu or "")
    end

    if opts.maxwidth ~= nil then
      local maxwidth = type(opts.maxwidth) == "function" and opts.maxwidth() or opts.maxwidth
      if vim.fn.strchars(vim_item.abbr) > maxwidth then
        vim_item.abbr = vim.fn.strcharpart(vim_item.abbr, 0, maxwidth)
          .. (opts.ellipsis_char ~= nil and opts.ellipsis_char or "")
      end
    end
    return vim_item
  end
end

return lspkind

-- vim: foldmethod=marker foldmarker={{{,}}}
