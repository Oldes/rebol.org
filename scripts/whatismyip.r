REBOL [
    Title: "What is my IP"
    File: %whatismyip.r
    Author: "Endo"
    Date: 2010-12-13
    Version: 0.0.0
    Purpose: {Prints your IP addresses}
    Library: [
        level: 'beginner
        platform: 'all
        type: [function one-liner]
        domain: [network]
        tested-under: [view 2.7.7.3.1 WindowsXP Win10] 
        support: none
        license: 'public-domain
        see-also: none
    ]
    Note: "Updated to use ident.me web site"
]

what-is-my-ip: has [ip quiet] [
	quiet: system/options/quiet
	system/options/quiet: true
	print [
		read join dns:// read dns://
		newline
		ip: read http://ident.me
	]
	system/options/quiet: quiet
	if system/product = 'View [
		write clipboard:// ip
	]
]
