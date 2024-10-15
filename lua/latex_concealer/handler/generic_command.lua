local extmark = require("latex_concealer.extmark")
local highlight = extmark.config.highlight
local counter = require("latex_concealer.counter")
local concealer = require("latex_concealer.handler.util").conceal
local filters = require("latex_concealer.filters")
local subscript_tbl = {
	["-"] = "₋",
	["0"] = "₀",
	["1"] = "₁",
	["2"] = "₂",
	["3"] = "₃",
	["4"] = "₄",
	["5"] = "₅",
	["6"] = "₆",
	["7"] = "₇",
	["8"] = "₈",
	["9"] = "₉",
}
local superscript_tbl = {
	["-"] = "⁻",
	["0"] = "⁰",
	["1"] = "¹",
	["2"] = "²",
	["3"] = "³",
	["4"] = "⁴",
	["5"] = "⁵",
	["6"] = "⁶",
	["7"] = "⁷",
	["8"] = "⁸",
	["9"] = "⁹",
}
local function frac_handler(buffer, node)
	local arg_nodes = node:field("arg")
	if #arg_nodes ~= 2 then
		return
	end
	local up = vim.treesitter.get_node_text(arg_nodes[1], buffer):sub(2, -2)
	local down = vim.treesitter.get_node_text(arg_nodes[2], buffer):sub(2, -2)
	if string.match(up .. down, "^[-]?[0-9-]*$") then
		up = up:gsub(".", superscript_tbl)
		down = down:gsub(".", subscript_tbl)
		return { up .. "/" .. down, highlight.fraction }
	end
	return { delim = { { "(", highlight.delim }, { ")/(", highlight.delim }, { ")", highlight.delim } } }
end
local function overline(buffer, node, opts)
	if not node:field("arg") or not node:field("arg")[1] then
		return
	end
	local text = vim.treesitter.get_node_text(node:field("arg")[1], buffer):sub(2, -2)
	if string.match(text, "^[a-zA-Z]$") then
		return { text .. "̅", "MathZone" }
	else
		return { delim = { { "‾", highlight.delim }, { "‾", highlight.delim } } }
	end
end
return {
	--command_delim
	["\\frac"] = frac_handler,
	["\\dfrac"] = frac_handler,
	["\\tfrac"] = frac_handler,
	["\\bar"] = overline,
	["\\overline"] = overline,
	["\\norm"] = { delim = { { "‖", highlight.delim }, { "‖", highlight.delim } } },
	["\\abs"] = { delim = { { "|", highlight.delim }, { "|", highlight.delim } } },
	--fonts
	["\\mathbb"] = { font = { filters.mathbb, "Special" } },
	["\\mathcal"] = { font = { filters.mathcal, "Special" } },
	["\\mathbbm"] = { font = { filters.mathbbm, "Special" } },
	["\\mathfrak"] = { font = { filters.mathfrak, "Special" } },
	["\\mathscr"] = { font = { filters.mathscr, "Special" } },
	["\\mathsf"] = { font = { filters.mathsf, "Special" } },
	["\\operatorname"] = { font = {
		function(str)
			return str
		end,
		highlight.operatorname,
	} },
	--other
	["\\footnote"] = function(buffer, node)
		counter.step_counter(buffer, "footnote")
		local arg_nodes = node:field("arg")
		if #arg_nodes < 2 then
			return
		end
		local a, b = node:range()
		local _, _, c, d = arg_nodes[1]:range()
		d = d + 1
		extmark.multichar_conceal(buffer, { a, b, c, d }, { counter.the(buffer, "footnote"), highlight.footnote })
		_, _, a, b = arg_nodes[2]:range()
		extmark.multichar_conceal(buffer, { a, b - 1, a, b }, "")
	end,
}
