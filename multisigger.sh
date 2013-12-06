#!/bin/bash

echo welcome to multisig 2of2 prompter
echo are you party a or b?
read PARTY

if [ "$PARTY" = "a" ]
then
OTHER="b"
elif  [ "$PARTY" = "b" ]
then 
OTHER="a"
else
exit 1
fi

if [ ! -e pubkey$OTHER ]
then
	if [ ! -e pubkey$PARTY ]
	then
	echo please enter you pubkey
	read PUBKEYPARTY
	echo $PUBKEYPARTY > pubkey$PARTY
        echo "waiting on $OTHER's pubkey"
	exit 0
	else
	echo "waiting on $OTHER's pubkey"
	exit 0
	fi
else
        if [ ! -e pubkey$PARTY ]
        then
        echo please enter you pubkey
        read PUBKEYPARTY
        echo $PUBKEYPARTY > pubkey$PARTY
	fi
fi

if [ ! -e multisigaddress ]
then
PUBKEYPARTY=$(cat pubkey$PARTY)
PUBKEYOTHER=$(cat pubkey$OTHER)
PUBCOMBO="[\"$PUBKEYPARTY\",\"$PUBKEYOTHER\"]"
echo $PUBCOMBO
bitcoind addmultisigaddress 2 $PUBCOMBO $USER > multisigaddress
echo You may now deposit coins to your escrow address
echo "address=$(cat multisigaddress)" 
fi

if [ -e multisigaddress ]
then
VALUE=$(bitcoind getbalance)	
	if [ ! -e rawtrans ]	
	then
		if [ "$VALUE" != "0.00000000" ]
		then
		echo value = $VALUE
		echo enter the address if you are ready to pay
		read RECADDR > recaddr
		bitcoind listunspent > TXDATA
		INPUTS="$(grep txid TXDATA)$(grep vout TXDATA)$(grepscriptPubKey TXDATA)$(grep redeemScript TXDATA)" 
        	OUTPUTS="\"$RECADDR\":$VALUE" ;
		INPUTS=${INPUTS// /}
		INPUTS=${INPUTS%,}
		echo $INPUTS
		echo $OUTPUTS
		bitcoind createrawtransaction [{$INPUTS}] {$OUTPUTS} > rawtrans
		echo created raw transacion:
		cat rawtrans
		else 
		echo waiting for deposit
		echo value=$VALUE
		fi	
	fi
fi

if [ ! -e signtrans$OTHER ]
then
	if [ ! -e signtrans$PARTY ]
	then
	echo please enter your privkey to pay $RECADDR
	read PRIVKEY$PARTY
        INPUTS="$(grep txid TXDATA)$(grep vout TXDATA)$(grep scriptPubKey TXDATA)$(grep redeemScript TXDATA)" 
	INPUTS=${INPUTS// /}
        INPUTS=${INPUTS%,}
	bitcoind signrawtransaction $(cat rawtrans) [{$INPUTS}] ["$PRIVKEY$PARTY"] > signtrans$PARTY
fi
fi



