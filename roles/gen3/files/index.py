#!/usr/bin/env python
from csv import DictReader, DictWriter

import sys
import logging
from uuid import uuid4

from boto3 import client, resource
from gen3.auth import Gen3Auth
from gen3.tools.indexing.index_manifest import index_object_manifest

logging.basicConfig(filename="output.log", level=logging.DEBUG)
logging.getLogger().addHandler(logging.StreamHandler(sys.stdout))

MANIFEST = "./manifest.tsv"
COMPLETED = "./completed.tsv"

MANIFEST_FIELDS = ['GUID', 'md5', 'size', 'acl', 'url', 'authz']


def get_s3_objects(bucket: str, prefix: str) -> dict:
    s3 = resource("s3")
    bucket = s3.Bucket(bucket)
    return {obj.key: obj for obj in bucket.objects.filter(Prefix=prefix)}
    # return [obj.key for obj in bucket.objects.filter(Prefix=prefix)]


def load_old_manifest(filename: str = COMPLETED) -> dict:
    with open(filename, "r") as f:
        reader = DictReader(f, delimiter="\t")
        return {row["GUID"]: row for row in reader}


def create_manifest(filename, s3_objects: dict) -> None:
    with open(filename, "w") as f:
        writer = DictWriter(f, fieldnames=MANIFEST_FIELDS, delimiter="\t")
        writer.writeheader()
        for key, s3_object in s3_objects.items():
            writer.writerow(s3_object)


def main():
    auth = Gen3Auth(refresh_file="credentials.json")

    already_uploaded = load_old_manifest()
    print(already_uploaded)

    s3_objects = get_s3_objects(bucket="gen3test-dane", prefix="PREFIX")
    new_manifest_dict = {}
    for key, s3_object in s3_objects.items():
        if key in already_uploaded:
            continue
        new_manifest_dict[key] = {
            "GUID": str(uuid4()),
            "md5": str(s3_object.e_tag).strip('"'),
            "size": s3_object.size,
            "acl": "[*]",
            "url": f"s3://gen3test-dane/{key}",
            "authz": "['/programs/eLwazi/projects/eLwaziProject']"
        }
    create_manifest(MANIFEST, new_manifest_dict)


    # use basic auth for admin privileges in indexd
    #auth = ("fence", "JH1EUMCPPL7YVStegs4b")

    whoop = index_object_manifest(
        commons_url="https://gen3.ilifu.ac.za/",
        manifest_file=MANIFEST,
        thread_num=8,
        auth=auth,
        replace_urls=True,
        manifest_file_delimiter="\t", # put "," if the manifest is csv file
        submit_additional_metadata_columns=False, # set to True to submit additional metadata to the metadata service
    )

    print(whoop)


if __name__ == "__main__":
    main()
