


data:extend({
	{
		type = "int-setting",
		name = "reader-count",
		setting_type = "startup",
		default_value = 50,
		minimum_value=10,
		maximum_value=250
	},
	{
		type = "int-setting",
		name = "reader-frequency",
		setting_type = "startup",
		default_value = 20,
		minimum_value=1,
		maximum_value=3600
	},
})
