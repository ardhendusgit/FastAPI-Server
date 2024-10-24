import boto3
from fastapi import FastAPI, status, HTTPException
#from pydantic import BaseModel

app = FastAPI()

# for post requests in CRUD. not using it here though.
#class Bucket(BaseModel):
    #name: str

s3 = boto3.client('s3')

def list_s3_objects(bucket_name: str, prefix: str = None):
    if prefix:
        # When prefix is provided, list contents within that "directory"
        response = s3.list_objects_v2(Bucket=bucket_name, Prefix=prefix)
        
        if 'Contents' in response:
            # Filter to get only the files inside the directory
            contents = [obj['Key'].split('/')[-1] for obj in response['Contents'] if obj['Key'] != f'{prefix}/']
            return {"content": contents}
        else:
            # Return empty list if no contents found
            return HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"This path does not exist.")
    else:
        # No prefix means we list top-level "directories"
        response = s3.list_objects_v2(Bucket=bucket_name, Delimiter='/')
        
        if 'CommonPrefixes' in response:
            # Extract the top-level directories
            directories = [prefix['Prefix'].rstrip('/') for prefix in response['CommonPrefixes']]
            return {"content": directories}
        else:
            return {"content": []}


# @app.get("/list-bucket-content")
# def get_bucket_root():
#     response = s3.list_buckets()
#     return {"Message": response}

@app.get("/list-bucket-content/{bucket_name}")
def get_bucket(bucket_name: str):
    try:
        return list_s3_objects(bucket_name)
    except Exception as e:
        if "(NoSuchBucket)" in str(e):
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="The entered bucket doesn't exist.")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@app.get("/list-bucket-content/{bucket_name}/{prefix}")
def get_bucket_prefix(bucket_name: str, prefix: str):
    try:
        return list_s3_objects(bucket_name, prefix)
    except Exception as e:
        if "(NoSuchBucket)" in str(e):
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="The entered bucket doesn't exist.")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))






# @app.get("/list-bucket-content")
# def get_bucket_root():
    
#     response = s3.list_buckets()

#     return {"Message": response}
#     #return {"Message": "You've entered an incomplete URL. Enter the URL in the format of http://assignment.ardhendushekhar.com/list-bucket-content/<path_to_the_bucket>"}

# @app.get("/list-bucket-content/{bucket_name}")
# def get_bucket(bucket_name: str):
#     #response = s3.list_objects_v2(Bucket=bucket_name)
#     #return {"Message": response}
#     try:
#         #tags = ["\"d41d8cd98f00b204e9800998ecf8427e\""]
#         objects = set()
#         response = s3.list_objects_v2(Bucket=bucket_name)
#         if "Contents" in response:
#             for element in response['Contents']:
#                 #if element['Key'][-1] == '/':
#                 objects.add(element['Key'].split('/')[0])
#             return {"content": objects}
#     except Exception as e:
#         if "(NoSuchBucket)" in str(e):
#             raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="The entered path doesn't exist.")

# @app.get("/list-bucket-content/{bucket_name}/{prefix}")
# def get_bucket_prefix(bucket_name: str, prefix: str):
#     try:
#         #objects = []
#         response = s3.list_objects_v2(Bucket=bucket_name, Prefix=prefix)
#         # if 'Contents' in response:
#         #     for element in response['Contents']:
#         #         if prefix in element['Key']:
#         #             ##continue   
#         #             objects.append(element['Key'].split('/')[-1])
#         #         else:
#         #             return {"content": []}
#         #     return {"content": objects[1:]}
#         return {"Message": response}
#     except Exception:
#         #if "(NoSuchBucket)" in str(e):
#         raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="The entered path doesn't exist.")
