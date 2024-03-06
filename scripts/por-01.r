REBOL [
    Title: "The Petals of the Rose"
    Date: 9-May-2005
    Version: 0.1
    File: %por-01.r
    Author: "Arie van Wingerden"
    Purpose:
    	{This is a small guessing game.
    	One should guess a number which is based upon
    		1. the name of the game
    		2. rolling the dice
    }
    Email: %apwing--zonnet--nl
    Library: [
        Level: 'intermediate 
        Platform: 'all 
        Type: 'game 
        Domain: 'game 
        Tested-under: ["Windows 2000" "REBOL/View 1.2.57.3.1"]  
        Support: none 
        License: none 
        See-also: none
    ]
]

roll-dice: func [
	/local i r
][
	sum: 0
	for i 1 6 1 [
		r: random 6
		switch r [
			3 [sum: sum + 2]
			5 [sum: sum + 4]
		]
		do rejoin ["i" i "/image: copy d/" r]
		msg/text: copy "Enter a guess and press Guess"
		msg/color: yellow
		guess/text: copy ""
		truth/text: copy ""
		focus guess
		show [i1 i2 i3 i4 i5 i6 msg guess truth]
	]
]

do-a-guess: func [
	/local err
][
	msg/color: yellow
	msg/text: copy ""
	if error? err: try [to-integer guess/text][
		disarm err
		msg/text: copy "Invalid guess!"
		show msg
		return
	]
	either sum <> to-integer guess/text [
		msg/text: copy "Incorrect guess - try again"
	][
		msg/text: copy "That's right - do you understand?"
		msg/color: green
	]
	truth/text: to-string sum
	show [msg truth]
]

story: "Each time press Roll to roll the dice. "
insert tail story "Then, taking into account the name of the game and " 
insert tail story "the outcome of rolling the dice, press Guess "
insert tail story "and see if your guess was right. "
insert tail story "Remember, the name of the game is important! "
story: head story

sum: 6

;;
;; The binary strings are the direct result of:
;;		read/binary %imagefile
;;
d: [1 2 3 4 5 6]
d/1: load to-binary decompress #{
	789C01B4004BFF47494638396120002000A10100FF0707FFFFFF7F0707000000
	2C000000002000200000026A448CA7C9EBF6629B4E2080B3DE9C0B7174E2A87D
	17896E5F98B698C9BAE82ABB709DD2F86CC5BB07FA916EC28EAE083C8D024C9F
	31886A3679CA8E94C97372AEDA522F25CD4191AA2FD9DB2D12CFAF311BB0661F
	DFF1F35C6EA6BBF1868FFF0F1828E817306878F857000021FE1F4F7074696D69
	7A656420627920556C65616420536D61727453617665722100003BF9F64B6DB4
	000000}
d/2: load to-binary decompress #{
	789C01BF0040FF47494638396120002000A10100FF0707FFFFFF7F0707000000
	2C0000000020002000000275448CA7C9EBF6629B4E2080B3DE9C0B7174E2A87D
	17896E5F98052E9BAA16FBBEB1076AB57BCBE70EEBAD74BB5E6946E41933C325
	CA1474CAA2D2E3A93AC58AA05A1C55CBED1EBFD8B018D394D6AC641290995317
	D148E79BDE76CF01E6E51A9EE7D4279676C637F391A8B8C8D89818E01829A958
	000021FE1F4F7074696D697A656420627920556C65616420536D617274536176
	65722100003BC60D52B6BF000000}
d/3: load to-binary decompress #{
	789C01C5003AFF47494638396120002000A10100FF0707FFFFFF7F0707000000
	2C000000002000200000027B448CA7C9EBF6629B4E2080B3DE9C0B7174E2A87D
	17896E5F9876C1CB0266DC62309CAD3577BFB945ABF558BA9D66F83B1921BE5F
	70E901424945D42D35B3F650D511922A257D475DD15894D536C1CF69B2ED2E5F
	A769260EDA3DEFEAFA5A7E8B17667317081727E8A602928806F4F108192939F9
	184079890959000021FE1F4F7074696D697A656420627920556C65616420536D
	61727453617665722100003B024B4E5FC5000000}
d/4: load to-binary decompress #{
	789C01CE0031FF47494638396120002000A10100FF0707FFFFFF7F0707000000
	2C0000000020002000000284448CA7C9EBF6629B4E2080B3DE9C0B7174E2A87D
	17896E5F98052E3BBEB0C9CA2E69B3AB96E376466BFD6243C04E28F325314124
	4CB4648252D492E5591D1DB3A92697B4FD6AAF62F0B43C3EA155E7B587EC663F
	A3C41B100EA1737A52181F5AE4F5D7F11736B8178897878568D717F7A6061906
	6974F58199A9B9C98919D0091A9A59000021FE1F4F7074696D697A6564206279
	20556C65616420536D61727453617665722100003B98485523CE000000}
d/5: load to-binary decompress #{
	789C01D3002CFF47494638396120002000A10100FF0707FFFFFF7F0707000000
	2C0000000020002000000289448CA7C9EBF6629B4E2080B3DE9C0B7174E2A87D
	17896E5F98052E3BBEB0C9CA2E69B3AB96E376466BFD6243C04E28F325314124
	4CB4648252D492E5591D1D5151ED955B146D89DD4E93FC428DA161F3177C534F
	B3D433DDFB2C77BAE71E3A6E3487E1C716D5D7B6413846B85764A7C7C12778E7
	7542E986756965F0D1E9F9091ADA19205A6AEA59000021FE1F4F7074696D697A
	656420627920556C65616420536D61727453617665722100003BB34E594ED300
	0000}
d/6: load to-binary decompress #{
	789C01DC0023FF47494638396120002000A10100FF0707FFFFFF7F0707000000
	2C0000000020002000000292448CA7C9EBF6629B4E2080B3DE9C0B7174E2A87D
	17896E5F98052E3BBEB0C9CA2E69B3AB96E376466BFD6243C04E28F325314124
	4CB4648252D492E5591D1D9DA9A8F1EABC11A35B8897D3939ED2D06299DD6137
	31E7F8CB8ACD8AE67AED947787E2350787E6F64757644706965807C80853B821
	D7E89847192885D96775D2D95106EA71F5617A8A9AAA6A1AB0EAFA7A5A000021
	FE1F4F7074696D697A656420627920556C65616420536D617274536176657221
	00003B53006099DC000000}
	
random/seed 6 now/time

view/title lay: layout [
	across
	label center 230 blue font-size 18 "The Petals of the Rose"
	return
	info wrap 230x95 story
	return
	i1: image d/1
	i2: image d/2
	i3: image d/3
	i4: image d/4
	i5: image d/5
	i6: image d/6
	return
	label 57
	button "Roll" [roll-dice]
	return
	label 70 copy "Guess: " font-name font-serif font-color blue
	guess: field 30 keycode [#"^m"] [do-a-guess]
	label 70 copy "     Should be: " font-name font-serif font-color blue
	truth: info 30
	return
	label 57
	button "Guess" [do-a-guess]
	return
	msg: info 230 copy "" yellow
	do [
		focus guess
	]
] "The Petals of the Rose"