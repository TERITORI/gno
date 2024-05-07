package inject_project

import (
	"std"

	"gno.land/r/demo/teritori/projects_manager"
)

func CreateDemoProject() {
	projects_manager.CreateContract(
		std.Address(""),
		std.CurrentRealm().Addr(),
		"ugnot",
		`{
			"shortDescData": {
				"name": "My Awesome Blog",
				"desc": "A blog about my awesome life",
				"tags": "frontend,ui,ux",
				"coverImg": "ipfs://bafybeihlfopxuwgrjjgkxn46j73dse4g3v5qcpv6z7ycaujpnu2qzpdaiq"
			},
        	"teamAndLinkData": {
				"websiteLink": "https://website.com",
				"twitterProfile": "https://twitter.com",
				"discordLink": "https://discord.com",
				"githubLink": "https://github.com",
				"teamDesc": "This is long team description"
			}
		}`,
		200000,
		"Bootstrap repository,Create Home page",
		"Create a GitHub repository with\n- These\n- Tech\n- Requirements,Create the Home page with\n- These\n- UI/UX\n- Requirements",
		"42,420",
		"3600,36000",
		",",
		"MS_PRIORITY_HIGH,MS_PRIORITY_MEDIUM",
		"g108cszmcvs4r3k67k7h5zuhm4el3qhlrxzhshtv",
	)
}
