#!/bin/bash
#
# lvmcache-statistics.sh displays the LVM cache statistics
# in a user friendly manner
#
# Copyright (C) 2014 Armin Hammer
# Copyright (C) 2023 Jaco Kroon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see http://www.gnu.org/licenses/.
#
# History:
# 20141220 hammerar, initial version
# 20230803 jkroon:
#   - amended to auto-detect and report on all cache volumes.
#   - work even if there are snapshots of cached volumes (albeit with extra -real after LV name)
#
##################################################################
set -o nounset

exec 3< <(exec dmsetup status --target cache) || exit 1

while IFS=' ' read -a RESULTS <&3; do
	##################################################################
	# Reference : https://www.kernel.org/doc/Documentation/
	##################################################################
	#
	# dmsetup status --target cache
	# vg-lv: 0 934174720 cache 8 5178/1310720 128 963/1638400 24453 7501 5164 492458 0 8 0 \
	# 1 writeback 2 migration_threshold 2048 mq 10 random_threshold 4 sequential_threshold 512 \
	# discard_promote_adjustment 1 read_promote_adjustment 4 write_promote_adjustment 8
	#
	# the VG or LV name will have a double - if there is a - in the name, eg:
	# v--g-l--v for vg=v-g and lv=l-v.

	if ! [[ "${RESULTS[0]}" =~ ^(([^-]|--)+)-(([^-]|--)+)(-real)?:$ ]]; then
		echo "ERROR: Unable to parse VG-LV from ${RESULTS[0]} (skipping)" >&2
		continue
	fi

	VG="${BASH_REMATCH[1]}"
	LV="${BASH_REMATCH[3]}"
	VG="${VG//--/-}"
	LG="${LV//--/-}"

	MetadataBlockSize="${RESULTS[4]}"
	NrUsedMetadataBlocks="${RESULTS[5]%%/*}"
	NrTotalMetadataBlocks="${RESULTS[5]##*/}"

	CacheBlockSize="${RESULTS[6]}"
	NrUsedCacheBlocks="${RESULTS[7]%%/*}"
	NrTotalCacheBlocks="${RESULTS[7]##*/}"

	NrReadHits="${RESULTS[8]}"
	NrReadMisses="${RESULTS[9]}"
	NrWriteHits="${RESULTS[10]}"
	NrWriteMisses="${RESULTS[11]}"

	NrDemotions="${RESULTS[12]}"
	NrPromotions="${RESULTS[13]}"
	NrDirty="${RESULTS[14]}"

	NrFeatureArgs="${RESULTS[15]}"
	FeatureArgs=(${RESULTS[@]:16:${NrFeatureArgs}})

	INDEX=$(( 16 + NrFeatureArgs ))

	NrCoreArgs="${RESULTS[$(( INDEX++ ))]}"
	CoreArgs=("${RESULTS[@]:${INDEX}:${NrCoreArgs}}")
	(( INDEX += NrCoreArgs ))

	PolicyName="${RESULTS[$(( INDEX++ ))]}"
	NrPolicyArgs="${RESULTS[$(( INDEX++ ))]}"
	PolicyArgs=("${RESULTS[@]:${INDEX}:${NrPolicyArgs}}")
	(( INDEX += NrPolicyArgs ))

	Mode="${RESULTS[$(( INDEX++ ))]}"

	##################################################################
	# human friendly output
	##################################################################
	echo "------------------------------------"
	echo "LVM Cache report of ${VG}/${LV} (${Mode})"
	echo "------------------------------------"

	MetaUsage=$( echo "scale=1;($NrUsedMetadataBlocks * 100) / $NrTotalMetadataBlocks" | bc)
	CacheUsage=$( echo "scale=1;($NrUsedCacheBlocks * 100) / $NrTotalCacheBlocks" | bc)
	echo "- Cache Usage: ${CacheUsage}% - Metadata Usage: ${MetaUsage}%"

	ReadRate=$(bc 2>/dev/null <<<"scale=1;($NrReadHits * 100) / ($NrReadMisses + $NrReadHits)")
	WriteRate=$(bc 2>/dev/null <<<"scale=1;($NrWriteHits * 100) / ($NrWriteMisses + $NrWriteHits)")
	echo "- Read Hit Rate: ${ReadRate:-na}% - Write Hit Rate: ${WriteRate:-na}%"
	echo "- Demotions/Promotions/Dirty: ${NrDemotions}/${NrPromotions}/${NrDirty}"
	echo "- Features in use: ${FeatureArgs[@]}"
	echo "- Policy in use: ${PolicyName} ${PolicyArgs[@]}"
done
