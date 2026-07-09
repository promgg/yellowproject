fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

author 'Athena'
description 'Ath_haras - Complete map package for RedM'
version '1.0.0'

-- Objectloader dependency
dependency 'objectloader'

-- Map and texture files
files { 
    'stream/*.ytyp',
    'stream/*.ydr',
    'stream/*.ytd',
    'stream/*.ymap',
    'Ath_em_trees.xml'
}

-- Data files for object types
data_file 'DLC_ITYP_REQUEST' 'stream/*.ytyp'

-- Objectloader for trees
objectloader_maps {
    'Ath_em_trees.xml'
}

-- Map configuration
this_is_a_map 'yes'

-- Files that should NOT be encrypted by CFX Escrow
escrow_ignore {
    'stream/*.ymap',
    'Ath_em_trees.xml',
}

dependency '/assetpacks'
dependency '/assetpacks-redm'