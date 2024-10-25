import boto3
from fastapi import FastAPI, status, HTTPException
from fastapi.responses import RedirectResponse
#from pydantic import BaseModel

app = FastAPI()

# for post requests in CRUD. not using it here though.
#class Bucket(BaseModel):
    #name: str

s3 = boto3.client('s3')

def list_s3_objects(bucket_name: str, prefix: str = None):
    if prefix:
        response = s3.list_objects_v2(Bucket=bucket_name, Prefix=prefix)
        
        if 'Contents' in response:
            contents = [obj['Key'].split('/')[-1] for obj in response['Contents'] if obj['Key'] != f'{prefix}/']
            return {"content": contents}
        else:
            return HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"This path does not exist.")
    else:
        response = s3.list_objects_v2(Bucket=bucket_name, Delimiter='/')
        
        if 'CommonPrefixes' in response:
            directories = [prefix['Prefix'].rstrip('/') for prefix in response['CommonPrefixes']]
            return {"content": directories}
        else:
            return {"content": []}

@app.get("/")
def read_root():
    # Option 1: Redirect to /list-bucket-content
    return RedirectResponse("/list-bucket-content")

    # Option 2: Alternatively, return a custom message
    # return {"message": "Welcome! Use /list-bucket-content to view S3 bucket contents."}

@app.get("/list-bucket-content")
def get_bucket_root():
    response = s3.list_buckets()
    bucket_names = [bucket['Name'] for bucket in response['Buckets']]
    return {"content": bucket_names}

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