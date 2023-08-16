import logging
import traceback
from google.cloud import storage, firestore
from vertexai.vision_models._vision_models import Image, ImageCaptioningModel
import os

model = ImageCaptioningModel.from_pretrained("imagetext@001")
db = firestore.Client()

def process_image(data, context):
    """Triggered from a message on a Cloud Pub/Sub topic."""
    logging.info("Function started.")
    logging.info("Received data: " + str(data))
    
    try:
        attributes = data.get('attributes', {})
        event_type = attributes.get('eventType')
        event_type = attributes['eventType']
        bucket_id = attributes['bucketId']
        object_id = attributes['objectId']
        
        if event_type != "OBJECT_FINALIZE":
            logging.info("Event type is not OBJECT_FINALIZE. Exiting function.")
            return "No action taken"

        # Initialize a client
        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_id)
        blob = bucket.blob(object_id)

        # Download the blob to a local file
        blob.download_to_filename(f'/tmp/{object_id}')
        logging.info(f'{object_id} downloaded to /tmp/{object_id}.')

        captions = get_captions(f'/tmp/{object_id}') 

        if captions:
            first_caption = captions[0]
            logging.info(first_caption)

            # Store filename and caption in Firestore
            doc_ref = db.collection('captions').document(object_id)
            doc_ref.set({
                'filename': object_id,
                'caption': first_caption
            })

            logging.info(f"Stored {object_id} and its caption in Firestore.")
    except Exception as e:
        stack_trace = traceback.format_exc()
        logging.error(f"Error during processing: {e}\n{stack_trace}")
    return "Processed image data"

def get_captions(filename):
    image = Image.load_from_file(filename)
    caption = model.get_captions(
        image=image,
        number_of_results=1,
        language="en",
    )
    return(caption)
