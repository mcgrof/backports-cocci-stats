#!/bin/bash                                                                     
#                                                                              
# Copyright 2015 Luis R. Rodriguez <mcgrof@do-not-panic.com>
# Copyright 2015 Julia Lawall <julia.lawall@lip6.fr>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# Tool to generate stats for Linux backports releases

# You only have to change these:
export BACKPORTS_DIR="${HOME}/backports/"
# you need to dump clean into your backports release.
export CLEAN="./clean"
export ALL_SMPL_CONCAT="./all-SmPL-patches-concatenated.cocci"
########### no need to change anything below #########################

function get_first_smpl_commit()
{
	git log --pretty="%H" --grep="apply backport SmPL patch" | tail -1
}

function get_last_smpl_commit()
{
	git log --pretty="%H" --grep="apply backport SmPL patch" | head -1
}

export FIRST_SMPL_COMMIT=$(get_first_smpl_commit)
export LAST_SMPL_COMMIT=$(get_last_smpl_commit)

function get_diffstat_count()
{
	git diff --stat $1..$2 | tail -1 | awk '{print $4+$6}'
}

function get_diff_wc()
{
	git diff $1..$2 | wc -l
}

function get_development_efficiency_total()
{
	# Note ~1, before the first smpl commit
	ALL_SMPL_DIFFSTAT=$(get_diffstat_count ${FIRST_SMPL_COMMIT}~1 $LAST_SMPL_COMMIT)
	echo > $ALL_SMPL_CONCAT
	for i in $(git log --pretty="%H" --grep="apply backport SmPL patch"); do
		SMPL_PATCH=$(git show --pretty="%s" $i  | head -1| awk -F"patch" '{print $2}' | awk '{print $1}')
		cat ${BACKPORTS_DIR}/patches/${SMPL_PATCH} >> $ALL_SMPL_CONCAT
	done
	CLEAN_STAT=$(./${CLEAN} $ALL_SMPL_CONCAT | awk '{print $4}')
	EFF=$(echo | awk '{print '${ALL_SMPL_DIFFSTAT}'/'${CLEAN_STAT}'}')
	DIFF_WC=$(get_diff_wc ${FIRST_SMPL_COMMIT}~1 $LAST_SMPL_COMMIT)
	MAINT_EFF=$(echo | awk '{print '${DIFF_WC}'/'${CLEAN_STAT}'}')
	printf "%18s\t%18s\t%8s\t%10s\t%10s\t%15s\n" $EFF $MAINT_EFF $DIFF_WC $ALL_SMPL_DIFFSTAT $CLEAN_STAT "all-SmPL.cocci"
}

function get_development_efficiency_single()
{
	printf "%18s\t%18s\t%8s\t%10s\t%10s\t%15s\n" "dev-efficiency" "maint-efficiency" "diff-wc" "diffstat" "clean" "SmPL-Patch"
	for i in $(git log --pretty="%H" --grep="apply backport SmPL patch"); do
		SMPL_PATCH=$(git show --pretty="%s" $i  | head -1| awk -F"patch" '{print $2}' | awk '{print $1}')
		SMPL_PATCH_NAME=$(basename $SMPL_PATCH)
		SMPL_DIFFSTAT=$(get_diffstat_count ${i}~1 ${i})
		CLEAN_STAT=$(./${CLEAN} ${BACKPORTS_DIR}/patches/${SMPL_PATCH} | awk '{print $4}')
		DIFF_WC=$(get_diff_wc ${i}~1 ${i})
		MAINT_EFF=$(echo | awk '{print '${DIFF_WC}'/'${CLEAN_STAT}'}')
		EFF=$(echo | awk '{print '${SMPL_DIFFSTAT}'/'${CLEAN_STAT}'}')
		# Note: $i is the commit id
		printf "%18s\t%18s\t%8s\t%10s\t%10s\t%15s\n" $EFF $MAINT_EFF $DIFF_WC $SMPL_DIFFSTAT $CLEAN_STAT $SMPL_PATCH_NAME
	done
}

echo -e "-----------------------------------------------------------------------------"
echo -e "Development and Maintenance efficiency metrics:"
echo -e "-----------------------------------------------------------------------------"
get_development_efficiency_single
get_development_efficiency_total
echo -e "-----------------------------------------------------------------------------"

function get_first_patch_commit()
{
	git log --pretty="%H" --grep="apply backport patch" | tail -1
}

function get_last_patch_commit()
{
	git log --pretty="%H" --grep="apply backport patch" | head -1
}

export FIRST_PATCH_COMMIT=$(get_first_patch_commit)
export LAST_PATCH_COMMIT=$(get_last_patch_commit)

# do we need anything computed with regular patches?

function compare_diff_smpl()
{
	PATCH_DIFF_WC=$(get_diff_wc ${FIRST_PATCH_COMMIT}~1 $LAST_PATCH_COMMIT)
	SMPL_DIFF_WC=$(get_diff_wc ${FIRST_SMPL_COMMIT}~1 $LAST_SMPL_COMMIT)
	TOTAL_DIFF_WC=$(($PATCH_DIFF_WC + $SMPL_DIFF_WC))
	echo "Patch total diff wc -l: $PATCH_DIFF_WC"
	echo "SmPL  total diff wc -l: $SMPL_DIFF_WC"
	echo "Total total diff wc -l: $TOTAL_DIFF_WC"
	echo "---------------------------------------"
	# x = contribution * 100 / total
	PATCH_CONTRIB=$(echo | awk '{print '${PATCH_DIFF_WC}' * 100 / '${TOTAL_DIFF_WC}'}')
	SMPL_CONTRIB=$(echo | awk '{print '${SMPL_DIFF_WC}' * 100 / '${TOTAL_DIFF_WC}'}')
	echo "Patch diff % contribution: ${PATCH_CONTRIB}"
	echo "SmPL  diff % contribution: ${SMPL_CONTRIB}"
}

compare_diff_smpl
