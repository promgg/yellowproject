fx_version "adamant"
rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."
game "rdr3"
lua54 "yes"
this_is_a_map "yes"
use_experimental_fxv2_oal 'yes'

author "Spooni"
description "Annesburg Reborn"

server_scripts {
  "server/*.lua",
}

client_scripts {
	"client/*.lua",
}

escrow_ignore {
  'stream/*.ydr', -- Ignore all .ydr
  'stream/[props]/*.ydr', -- Ignore all .ydr
  'README.md',
}

files {
  'stream/[props]/*.ytyp'
}

data_file 'DLC_ITYP_REQUEST' 'stream/[props]/*.ytyp'

dependency '/assetpacks'