/* See COPYRIGHT for copyright information. */

#ifndef JOS_INC_ERROR_H
#define JOS_INC_ERROR_H

enum {
	// Kernel error codes -- keep in sync with list in lib/printfmt.c.
	E_UNSPECIFIED	= 1,	// Unspecified or unknown problem
	E_BAD_ENV	= 2,	// Environment doesn't exist or otherwise
				// cannot be used in requested action
	E_INVAL		= 3,	// Invalid parameter
	E_NO_MEM	= 4,	// Request failed due to memory shortage
	E_NO_FREE_ENV	= 5,	// Attempt to create a new environment beyond
				// the maximum allowed
	E_FAULT		= 6,	// Memory fault
	E_NO_SYS	= 7,	// Unimplemented system call

	MAXERROR
};

#endif	// !JOS_INC_ERROR_H */
