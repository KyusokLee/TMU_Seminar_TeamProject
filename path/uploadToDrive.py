## /home/zemi/start/python_code/uploadToDrive.py
## Googledriveにファイルをアップロードするコード
import os

from pydrive2.auth import GoogleAuth
from pydrive2.drive import GoogleDrive


class GoogleDriveFacade:
    
    def __init__(self, setting_path: str='/home/zemi/start/python_code/settings.yaml'):
        gauth = GoogleAuth(setting_path)
        gauth.LocalWebserverAuth()

        self.drive = GoogleDrive(gauth)

    def create_folder(self, folder_name):
        ret = self.check_files(folder_name)
        if ret:
            folder = ret
            print(f"{folder['title']}: exists")
        else:   
            folder = self.drive.CreateFile(
                {
                    'title': folder_name,
                    #IoT_for_B3
                    'parents': [{'id':'1aIV9nZ42tzspbZ_gPo_AaueqAhcSQrEg'}],
                    'mimeType': 'application/vnd.google-apps.folder'
                }
            )
            folder.Upload()

        return folder

    def check_files(self, folder_name,):
        query = f'title = "{os.path.basename(folder_name)}"'

        list = self.drive.ListFile({'q': query}).GetList()
        if len(list)> 0:
            return list[0]
        return False

    def upload(self, 
               local_file_path: str,
               save_folder_name: str = 'gps_log_data',
               is_convert : bool=True,
        ):
        
        if save_folder_name:
            folder = self.create_folder(save_folder_name)
        
        file = self.drive.CreateFile(
            {
                #gps_log_data/id
                'id': '1KsyeVj5Nof3xLbT-DcXTr8y5mpFPRqvVVb2T-1ZwdoU',
                'title':os.path.basename(local_file_path),
                'parents': [{'id':'1l5d9HQoldezXaJ9wIiUKhJVJPov8nxLP'}]
            }
        )
        file.SetContentFile(local_file_path)
        file.Upload({'convert': is_convert})
        
        drive_url = f"https://drive.google.com/uc?id={str( file['id'] )}" 
        return drive_url
    
        
if __name__ == "__main__":
    try:
        g = GoogleDriveFacade()
        g.upload(
            local_file_path='/home/zemi/start/python_code/gps_log.csv',
            save_folder_name='gps_log_data',
            is_convert=True,
            )
    except:
        pass
    
