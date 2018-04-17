CONFIG <- new.env(parent = emptyenv())

#' Initialize AWS configuration for the library.
#'
#' @param bucket
#' @param profile
initialize <- function(bucket = NULL, profile = "default") {
  CONFIG[['bucket']] <- bucket
  CONFIG[['profile']] <- profile
  aws.signature::use_credentials(profile = profile)
}


#' List datasets available in the configured bucket.
#'
#' @return
#' @export
#'
#' @examples
datasets <- function() {
  aws.signature::use_credentials(profile = CONFIG[["profile"]])

  aws.s3::get_bucket(CONFIG[['bucket']]) %>%
    purrr::map_chr(~ stringr::str_match(.$Key, "(.*)/")[2]) %>%
    purrr::discard(~ is.na(.)) %>%
    purrr::reduce(union)
}


#' Read a named dataset from the data catalogue bucket.
#'
#' @param dataset_name
#'
#' @return data frame of the dataset
read_dataset <- function(dataset_name) {
  aws.signature::use_credentials(profile = CONFIG[["profile"]])
  bucket <- CONFIG[["bucket"]]

  path <- paste0(dataset_name, "/")
  versions <- aws.s3::get_bucket(bucket, prefix=path) %>%
    purrr::map_chr(~ .$Key) %>%
    purrr::keep(~ . != path) %>%
    unname() %>%
    stringr::str_sort(decreasing = FALSE)

  dataset_key <- versions[1]
  reader <- switch(tools::file_ext(dataset_key),
                   feather=feather::read_feather,
                   csv=readr::read_csv)

  filename <- tempfile()
  aws.s3::save_object(dataset_key, bucket=bucket, filename)

  reader(filename)
}

#' Write a dataset into S3
#'
#' @param df
#' @param format
#' @param ...
#'
#' @return
#' @export
#'
#' @examples
write_dataset <- function(df, format = "feather", ...) {
  aws.signature::use_credentials(profile = CONFIG[["profile"]])

  dataset_name <- as.character(substitute(df))
  today <- format(Sys.time(), "%Y%m%d")
  key <- stringr::str_interp("${dataset_name}/${today}-${dataset_name}.${format}")

  writer <- switch(format,
                   feather=feather::write_feather,
                   csv=readr::write_csv)

  filename <- tempfile()
  writer(df, filename, ...)

  aws.s3::put_object(filename, key, CONFIG[["bucket"]])
}
