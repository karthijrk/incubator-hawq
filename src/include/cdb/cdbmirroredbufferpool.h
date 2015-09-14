/*-------------------------------------------------------------------------
 *
 * cdbmirroredbufferpool.h
 *
 * Copyright (c) 2009-2010, Greenplum inc
 *
 *-------------------------------------------------------------------------
 */
#ifndef CDBMIRROREDBUFFERPOOL_H
#define CDBMIRROREDBUFFERPOOL_H

#include "utils/palloc.h"
#include "storage/fd.h"
#include "storage/relfilenode.h"
#include "catalog/catalog.h"
#include "storage/smgr.h"

/*
 * This module is for doing mirrored writes for relation files currently managed by the
 * Buffer Pool.
 *
 * It is intended for use by the Background Writer process through the BufMgr module.
 */

/*
 * This structure contains write open information.  Consider the fields
 * inside to be private.
 */
typedef struct MirroredBufferPoolOpen
{
	bool		isActive;
	RelFileNode relFileNode;
	uint32		segmentFileNum;
	File		primaryFile;
	bool						create;
} MirroredBufferPoolOpen;

// -----------------------------------------------------------------------------
// Open, Flush, Close 
// -----------------------------------------------------------------------------

/*
 * Open a relation for mirrored write.
 */
extern void MirroredBufferPool_Open(
	MirroredBufferPoolOpen *open,
				/* The resulting open struct. */

	RelFileNode 	*relFileNode,
				/* The tablespace, database, and relation OIDs for the open. */

	uint32			segmentFileNum,
				/* Which segment file. */

	char			*relationName,
				/* For tracing only.  Can be NULL in some execution paths. */
	
	int 			*primaryError);

extern void MirroredBufferPool_Create(
	MirroredBufferPoolOpen		*open,
				/* The resulting open struct. */

	RelFileNode 				*relFileNode,
				/* The tablespace, database, and relation OIDs for the open. */

	uint32						segmentFileNum,
				/* Which segment file. */

	char						*relationName,
				/* For tracing only.  Can be NULL in some execution paths. */

	int 						*primaryError);

extern bool MirroredBufferPool_IsActive(
	MirroredBufferPoolOpen *open);
				/* The open struct. */
				
/*
 * Flush a Buffer Pool relation file.
 */
extern bool MirroredBufferPool_Flush(
	MirroredBufferPoolOpen *open);
				/* The open struct. */
				
/*
 * Close a Buffer Pool relation file.
 */
extern void MirroredBufferPool_Close(
	MirroredBufferPoolOpen *open);
				/* The open struct. */


extern void MirroredBufferPool_Drop(
	RelFileNode 				*relFileNode,
	 
	int32						segmentFileNum,

	char						*relationName,
					/* For tracing only.  Can be NULL in some execution paths. */
	bool						isRedo,
	
	int 						*primaryError);

/*
 * Write a Buffer Pool page mirrored.
 */
extern bool MirroredBufferPool_Write(
	MirroredBufferPoolOpen *open,
				/* The open struct. */

	int32		position,

	void		*buffer,
				/* Pointer to the Buffer Pool page, properly protected by locks. */

	int32		bufferLen);

extern int MirroredBufferPool_Read(
	MirroredBufferPoolOpen *open,
				/* The open struct. */

	int32		position,

	void		*buffer,
				/* Pointer to the Buffer Pool page, properly protected by locks. */

	int32		bufferLen);

extern int64 MirroredBufferPool_SeekSet(
	MirroredBufferPoolOpen *open,
				/* The open struct. */

	int32		position);

extern int64 MirroredBufferPool_SeekEnd(
	MirroredBufferPoolOpen *open);
				/* The open struct. */

extern bool MirroredBufferPool_Truncate(
	MirroredBufferPoolOpen *open,
				/* The open struct. */

	int64		position);

#endif   /* CDBMIRROREDBUFFERPOOL_H */
