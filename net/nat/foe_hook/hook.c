/*
 ***************************************************************************
 * Ralink Tech Inc.
 * 4F, No. 2 Technology 5th Rd.
 * Science-based Industrial Park
 * Hsin-chu, Taiwan, R.O.C.
 *
 * (c) Copyright 2002-2006, Ralink Technology, Inc.
 *
 * All rights reserved. Ralink's source code is an unpublished work and the
 * use of a copyright notice does not imply otherwise. This source code
 * contains confidential trade secret material of Ralink Tech. Any attempt
 * or participation in deciphering, decoding, reverse engineering or in any
 * way altering the source code is stricitly prohibited, unless the prior
 * written consent of Ralink Technology, Inc. is obtained.
 ***************************************************************************

    Module Name:
    
    hook.c

    Abstract:

    Revision History:
    Who         When            What
    --------    ----------      ----------------------------------------------
    Name        Date            Modification logs
    Steven Liu  2006-10-06      Initial version
*/

#include <linux/version.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/types.h>
#include <linux/skbuff.h>

int (*ra_sw_nat_hook_rx) (struct sk_buff * skb) = NULL;
int (*ra_sw_nat_hook_tx) (struct sk_buff * skb, int gmac_no) = NULL;
struct FoeEntry		*PpeFoeBase;
EXPORT_SYMBOL(PpeFoeBase);
struct FoeEntry *ppe_virt_foe_base_tmp;
EXPORT_SYMBOL(ppe_virt_foe_base_tmp);
#if defined (CONFIG_RA_HW_NAT_WIFI_NEW_ARCH)
void (*ppe_dev_register_hook) (struct net_device *dev);
void (*ppe_dev_unregister_hook) (struct net_device *dev);
EXPORT_SYMBOL(ppe_dev_register_hook);
EXPORT_SYMBOL(ppe_dev_unregister_hook);
#endif
EXPORT_SYMBOL(ra_sw_nat_hook_rx);
EXPORT_SYMBOL(ra_sw_nat_hook_tx);

