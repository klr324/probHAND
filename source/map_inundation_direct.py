import pandas as pd
import os
from source import constants, paths, driver, preprocessing


def export_inundation(ws, huc12, n, resolution, percentile, reach_type):
    ws_id = constants.ws_id_dict[ws]
    huc12_id = huc12.split('_')[1]
    paths_dict = paths.gen_paths(ws, ws_id, huc12_id, reach_type)

    hand_1m_uri = paths_dict['hand_uri']
    paths_dict['hand_uri'] = hand_1m_uri[:-4] + '_imputed1m.tif'

    data_dict = preprocessing.read_data2mem(paths_dict, resolution)
    RIstage_logbook_fn = 'RIstage_logbook.csv'
    RIstage_logbook_uri = os.path.join(paths_dict['logbooks_dir'], RIstage_logbook_fn)
    RIstage_df = pd.read_csv(RIstage_logbook_uri)
    for p in percentile:
        driver.map_inun(RIstage_df, data_dict, p, resolution, paths_dict)

def main():
#    h12_list = ["LKC_0104","LKC_0301","LKC_0304","LKC_0401","LKC_0402","LKC_0501","LKC_0502","LKC_0602","LKC_0801","LKC_0802","LKC_0901","LKC_0902","LKC_1001","LKC_1004","LKC_1101","LKC_1201","LKC_1202","LKC_1203"]
    h12_list = ["LWBS_0507", "LWBS_0605", "LWBS_0505", "LWBS_0503", "LWBS_0504", "LWBS_0506," "LWBS_0508","LWBS_0204", "LWBS_0203", "LWBS_0202", "LWBS_0201", "LWBS_0205", "LWBS_0103", "LWBS_0207","LWBS_0208", "LWBS_0604", "LWBS_0206", "LWBS_0509"]
    for h12 in h12_list:
        print(f'Processing basin {h12}')
        export_inundation('Susquehanna_Subregion', h12, 1000, 1, [1], 'NHD')
        #export_inundation('Lake_Champlain', h12, 1000, 1, [1], 'NHD')


if __name__ == '__main__':
    main()
