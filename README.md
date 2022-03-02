# UDP_DATA_SERVER

commands:
#	CREATE;ID;BUF_LEN
#		create buffer for ID with length BUF_LEN
#
#	DEL;ID
#		delete buffer for ID
#
#	LIST;ID;BUF_LEN
#		list last BUF_LEN records for ID
#
#	PUSH;ID;VAL
#		insert new VAL for ID
#
#	DUMP;ALL
#		dump structure of all buffers into file 
#
#	LOAD;LAST
#		load buffers structure from las dump file
#
#	SEARCH;ID
#		serch for buffers id like ID
#
#	INC;ID;VAL
#		increase value of ID by VAL
#
#	READRESET;ID
#		get last val of ID and reset it to ZERO
#	
#	DELAY;TIME
#		get time difference Trecieve-Tsend
#
#	LOG_ON
#		start LOG
#
#	LOG_OFF
#		stop LOG
#
#	DEBUG
#   start debug messages
#
# NO_DEBUG
#    stop debug messages
#
