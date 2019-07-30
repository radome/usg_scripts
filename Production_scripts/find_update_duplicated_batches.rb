select distinct id_flowcell_lims
from iseq_flowcell
where recorded_at >'2019-07-01'
and id_flowcell_lims NOT IN (65873)
group by id_flowcell_lims, position, tag_index
having count(*) > 1
order by id_flowcell_lims;

select distinct id_pac_bio_run_lims
from pac_bio_run
where recorded_at >'2019-07-01'
group by id_pac_bio_run_lims, pac_bio_library_tube_id_lims, well_label
having count(*) > 1
order by id_pac_bio_run_lims;


ids=[
  69101
]
Batch.where(id: ids).each {|b| b.touch}

ids = [
  68794,
  69161,
  69163,
  69165,
  69166,
  69201,
  69239
]