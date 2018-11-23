import os
from os import path


def get_cadfile(id, db_path):
    cad_path = path.join(db_path, '{}'.format(id))
    if path.exists(cad_path):
        db_data = os.listdir(cad_path)
        return db_data[0]
    else:
        return False
