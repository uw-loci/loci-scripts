// Make Bio-Formats load things faster.
// see: https://github.com/openmicroscopy/bioformats/issues/2255
call("loci.common.NIOFileHandle.setDefaultBufferSize",16);
