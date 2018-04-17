# catalogr

Manage a catalogue of datasets in AWS with R.

```r
library(catalogr)

# Initialize `catalogr` with the name of your dataset bucket and AWS profile.
initialize(bucket = 'us-east-1-datasets-example', profile = 'default')

# Write a dataset.
write_dataset(mtcars)

# List defined datasets.
datasets()
# [1] "mtcars"

# Read dataset from S3 into memory.
df <- read_dataset("mtcars")
```

## How does it work?

`catalogr` stores date-stamped versions of data sets under a prefix named after the dataset in S3.

    dataset_name/yyyymmdd-dataset_name.feather

It prefers the feather format unless you specify CSV. When you read the dataset, the most-recent version is returned.
