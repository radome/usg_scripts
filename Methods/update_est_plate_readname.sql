select distinct sm.samplename
from loadingsample ls, dnaplate_map dm, bb_map bm, sourceplate_map sm, seqchem_seqprotocol ss, seqchemistry s, pt_vector ptv, rowcol_map rcm, request_map rm, finish_request fr, primer p
where ls.id_scsp = ss.id_scsp
and ss.id_seqchem = s.id_seqchem
and s.id_ptv = ptv.id_ptv
and ls.id_dnaplatemap = dm.id_dnaplatemap
and ls.id_map = rcm.id_map
and dm.id_bbmap = bm.id_bbmap
and bm.id_sourceplatemap = sm.id_sourceplatemap
and ls.id_loadingsample = rm.id_loadingsample (+)
and rm.id_frequest = fr.id_frequest (+)
and fr.id_primer = p.id_primer (+)
and ls.id_loadingplate = 1916683;

update sourceplate_map set samplename = 'MGPR_CRISPR4_A_2_1a09' where samplename = 'MGPR_CRISPR4A2_1a09';

update sourceplate_map set samplename = substr(samplename,0,12)||substr(samplename,14,1)||substr(samplename,16,1)||substr(samplename,17,5) where
samplename IN (select distinct sm.samplename
from loadingsample ls, dnaplate_map dm, bb_map bm, sourceplate_map sm, seqchem_seqprotocol ss, seqchemistry s, pt_vector ptv, rowcol_map rcm, request_map rm, finish_request fr, primer p
where ls.id_scsp = ss.id_scsp
and ss.id_seqchem = s.id_seqchem
and s.id_ptv = ptv.id_ptv
and ls.id_dnaplatemap = dm.id_dnaplatemap
and ls.id_map = rcm.id_map
and dm.id_bbmap = bm.id_bbmap
and bm.id_sourceplatemap = sm.id_sourceplatemap
and ls.id_loadingsample = rm.id_loadingsample (+)
and rm.id_frequest = fr.id_frequest (+)
and fr.id_primer = p.id_primer (+)
and ls.id_loadingplate = 1916682);

update sourceplate_map set samplename = 'MGPZ0003_A_1_1_1b01' where samplename = 'MGPZ0003_A1_1_1b01';


update sourceplate_map set samplename = substr(samplename,0,10)||substr(samplename,12,8) where
samplename IN (select distinct sm.samplename
from loadingsample ls, dnaplate_map dm, bb_map bm, sourceplate_map sm, seqchem_seqprotocol ss, seqchemistry s, pt_vector ptv, rowcol_map rcm, request_map rm, finish_request fr, primer p
where ls.id_scsp = ss.id_scsp
and ss.id_seqchem = s.id_seqchem
and s.id_ptv = ptv.id_ptv
and ls.id_dnaplatemap = dm.id_dnaplatemap
and ls.id_map = rcm.id_map
and dm.id_bbmap = bm.id_bbmap
and bm.id_sourceplatemap = sm.id_sourceplatemap
and ls.id_loadingsample = rm.id_loadingsample (+)
and rm.id_frequest = fr.id_frequest (+)
and fr.id_primer = p.id_primer (+)
and ls.id_loadingplate = 1915980);

