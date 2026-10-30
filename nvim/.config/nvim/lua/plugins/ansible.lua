-- Ansible files colored like the VS Code Ansible extension (Dark Modern palette)
local colors = {
  key = "#569CD6",
  string = "#CE9178",
  number = "#B5CEA8",
  comment = "#6A9955",
  variable = "#9CDCFE",
  filter = "#DCDCAA",
  control = "#C586C0",
  operator = "#D4D4D4",
}

local function set_colors()
  local groups = {
    ["@property.yaml"] = colors.key,
    ["@string.yaml"] = colors.string,
    ["@number.yaml"] = colors.number,
    ["@boolean.yaml"] = colors.key,
    ["@constant.builtin.yaml"] = colors.key,
    ["@comment.yaml"] = colors.comment,
    ["@punctuation.delimiter.yaml"] = colors.operator,
    ["@keyword.directive.jinja"] = colors.key,
    ["@variable.jinja"] = colors.variable,
    ["@variable.member.jinja"] = colors.variable,
    ["@variable.parameter.jinja"] = colors.variable,
    ["@function.call.jinja"] = colors.filter,
    ["@function.builtin.jinja"] = colors.filter,
    ["@keyword.jinja"] = colors.control,
    ["@keyword.conditional.jinja"] = colors.control,
    ["@keyword.repeat.jinja"] = colors.control,
    ["@keyword.import.jinja"] = colors.control,
    ["@keyword.operator.jinja"] = colors.control,
    ["@operator.jinja"] = colors.operator,
    ["@punctuation.bracket.jinja"] = colors.operator,
    ["@punctuation.delimiter.jinja"] = colors.operator,
    ["@string.jinja"] = colors.string,
    ["@number.jinja"] = colors.number,
    ["@number.float.jinja"] = colors.number,
    ["@boolean.jinja"] = colors.key,
    ["@constant.jinja"] = colors.key,
    ["@comment.jinja"] = colors.comment,
  }
  for group, fg in pairs(groups) do
    vim.api.nvim_set_hl(0, group, { fg = fg })
  end
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      vim.filetype.add({
        extension = { j2 = "jinja", jinja2 = "jinja" },
        pattern = {
          [".*/defaults/.*%.ya?ml"] = "yaml.ansible",
          [".*/group_vars/.*%.ya?ml"] = "yaml.ansible",
          [".*/host_vars/.*%.ya?ml"] = "yaml.ansible",
          [".*/playbooks?/.*%.ya?ml"] = "yaml.ansible",
          [".*/playbook[^/]*%.ya?ml"] = "yaml.ansible",
          [".*/tasks/.*%.ya?ml"] = "yaml.ansible",
          [".*/handlers/.*%.ya?ml"] = "yaml.ansible",
          [".*/molecule/.*%.ya?ml"] = "yaml.ansible",
        },
      })
      vim.treesitter.language.register("yaml", "yaml.ansible")
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_colors })
      set_colors()
    end,
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, { "yaml", "jinja", "jinja_inline" })
    end,
  },
}
