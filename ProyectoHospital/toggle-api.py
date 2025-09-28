import sys 
import os 
 
def toggle_api_mode(mode): 
    settings_file = 'ProyectoHospital/ProyectoHospital/settings.py' 
    if not os.path.exists(settings_file): 
        print("❌ Error: No se encuentra el archivo settings.py") 
        return 
    with open(settings_file, 'r') as f: 
        content = f.read() 
    if mode == 'production': 
        content = content.replace("SERVERLESS_API_URL = 'http://localhost:3000'", "SERVERLESS_API_URL = 'https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api'") 
        print("✅ API configurada para PRODUCCIÓN") 
    elif mode == 'local': 
        content = content.replace("SERVERLESS_API_URL = 'https://rc3ltywoub.execute-api.us-east-1.amazonaws.com/dev/api'", "SERVERLESS_API_URL = 'http://localhost:3000'") 
        print("✅ API configurada para DESARROLLO LOCAL") 
    with open(settings_file, 'w') as f: 
        f.write(content) 
 
if __name__ == '__main__': 
    mode = sys.argv[1] if len(sys.argv) > 1 else 'production' 
    toggle_api_mode(mode) 
