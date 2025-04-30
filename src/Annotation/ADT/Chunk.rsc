/*
 * @Module: Verb
 * @Desc:   Module that contains all the module extension functionality
 * @Auth:   Borja Velasco -> code, comments
 */

module Annotation::ADT::Chunk

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   ChunkAnno
 * @Desc:   Structure to model an chunk annotation
 */
data ChunkAnnotation
    = chunk_annotation(
        str name,
        str \module,
        str playtrace_type,
        tuple[
            str prev,
            str next
        ] dependencies
    )
    | chunk_annotation_empty()
    ;