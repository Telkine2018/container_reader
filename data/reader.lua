local reader = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
reader.name = "container_reader"
reader.icon_size = 64
reader.icon = "__container_reader__/graphics/icons/reader.png"
reader.item_slot_count = settings.startup["reader-count"].value
reader.minable = { hardness = 0.2, mining_time = 0.2, result = "container_reader" }

for _, dir in pairs(reader.sprites) do
	dir.layers[1].filename = "__container_reader__/graphics/entity/hr-reader.png"
	dir.layers[2].filename = "__container_reader__/graphics/entity/hr-reader-shadow.png"
end

data:extend
{
	reader,
	{
		type = "item",
		name = "container_reader",
		icon_size = 64,
		icons = {
			{
				icon = "__container_reader__/graphics/icons/reader.png",
			},
		},
		subgroup = "circuit-network",
		order = "c[ontainer_reader]",
		stack_size = 50,
		place_result = "container_reader"
	}
	, {
	type = "recipe",
	name = "container_reader",
	enabled = true,
	ingredients =
	{
		{ type = "item", name = "iron-plate",         amount = 5 },
		{ type = "item", name = "electronic-circuit", amount = 5 },
		{ type = "item", name = "copper-cable",       amount = 5 }
	},
	results = { { type = "item", name = "container_reader", amount = 1 } }
}
}
