#!/usr/bin/env Rscript
.libPaths("~/R_packages")
require(plotly)
require(rowr)

Sys.setenv("plotly_username" = "sjen")
Sys.setenv("plotly_api_key" = "7xblqr4HsNp3qVueLko0")

all_end_times_df <- data.frame() # declare empty dataframe

log_paths = c("../../realf5p_data/1500/logs",
          "../../realf5p_data/5000/logs")

#for (log_dir in log_paths) {
    # seq_sum_files <- list.files(path = log_dir,
    #                             pattern = "s*.txt$",
    #                             full.names = T,
    #                             recursive = F)
    
    # file_end_times_df <- data.frame(matrix(ncol = 2, nrow = 0)) # declare empty dataframe
    # colnames(file_end_times_df) <- c("end_time", "num_bases")

    # for (seq_file in seq_sum_files) {
    #     seq_sum_df <- read.table(seq_file,
    #                              sep = "\t",
    #                              header = T)

    #     end_time <- 0
    #     for (row in 1:nrow(seq_sum_df)) {
    #         start_time <- seq_sum_df[row, "start_time"]
    #         duration <- seq_sum_df[row, "duration"]

    #         if (start_time + duration > end_time) {
    #             end_time <- start_time + duration
    #         }
#         }

#         seq_sum_file_path <- seq_file
#         seq_sum_file_pathless <- system(paste0("basename ", seq_sum_file_path), intern = T)
#         file_id <- 
#             system(paste0("file_pathless='", seq_sum_file_pathless, "';",
#                           "file_extless=${file_pathless%.*};",
#                           "temp=${file_extless##*.};",
#                           "echo $temp"), intern = T)
#         fastq_file <- paste0("fastq_*.", file_id, ".fastq.gz")
#         num_bases <- 
#             system(paste0("zcat ", log_dir, "/../fastq/", fastq_file, " |",
#                           "awk 'BEGIN {sum = 0}",
#                           "{ if(NR % 4 == 2) {sum = sum + length($0);} }",
#                           "END {print sum}'"), intern = T)

#         file_end_times_df[nrow(file_end_times_df) + 1, ] <- c(end_time, num_bases)
#     }

#     file_end_times_df[] <- lapply(file_end_times_df, function(x) as.numeric(as.character(x)))
#     file_end_times_df <- file_end_times_df[with(file_end_times_df, order(end_time)), ]
#     file_end_times_df["end_time"] <- file_end_times_df["end_time"] / 3600 # Get time in hours (3600s in 1h)
#     file_end_times_df <- within(file_end_times_df, total_bases <- cumsum(num_bases))
#     file_end_times_df["total_bases"] <- file_end_times_df["total_bases"] / (10 ^ 9) # Convert to gigabases
    
#     print(file_end_times_df) # testing

#     all_end_times_df <- cbind.fill(all_end_times_df, file_end_times_df, fill = NA)
# }




# NA dataset
seq_sum_dirs_NA <- list.dirs(path = "../../realf5p_data/NA/",
                             full.names = T,
                             recursive = F)

file_end_times_df <- data.frame(matrix(ncol = 2, nrow = 0)) # declare empty dataframe
colnames(file_end_times_df) <- c("end_time", "num_bases")

for (seq_dir in seq_sum_dirs_NA) {
    seq_sum_df <- read.table(paste0(seq_dir, "/sequencing_summary.txt"),
                             sep = "\t",
                             header = T)

    end_time <- 0
    for (row in 1:nrow(seq_sum_df)) {
        start_time <- seq_sum_df[row, "start_time"]
        duration <- seq_sum_df[row, "duration"]

        if (start_time + duration > end_time) {
            end_time <- start_time + duration
        }
    }

    dir_number <- system(paste0("basename ", seq_dir), intern = T)
    num_bases <- system(paste0("bash get_bases.sh ", dir_number, " NA_file_bases.csv"), intern = T)

    file_end_times_df[nrow(file_end_times_df) + 1, ] <- c(end_time, num_bases)
}

file_end_times_df[] <- lapply(file_end_times_df, function(x) as.numeric(as.character(x)))
file_end_times_df <- file_end_times_df[with(file_end_times_df, order(end_time)), ]
file_end_times_df["end_time"] <- file_end_times_df["end_time"] / 3600 # Get time in hours (3600s in 1h)
file_end_times_df <- within(file_end_times_df, total_bases <- cumsum(num_bases))
file_end_times_df["total_bases"] <- file_end_times_df["total_bases"] / (10 ^ 9) # Convert to gigabases

print(file_end_times_df) # testing

all_end_times_df <- cbind.fill(all_end_times_df, file_end_times_df, fill = NA)

all_end_times_df <- all_end_times_df[-c(1)]
colnames(all_end_times_df) <- c("time_1500", "solo_bases_1500", "tot_bases_1500",
                                "time_5000", "solo_bases_5000", "tot_bases_5000",
                                "time_NA", "solo_bases_NA", "tot_bases_NA"))
print(all_end_times_df) # testing





# processing dataset
processing_logs <- c("../logs.txt") # (todo: change to legitimate location later)
processing_times <- system(paste0("bash extract_analysis_timestamps.sh ", processing_logs[1]), intern = T)
processing_df <- read.csv(text = processing_times, sep = " ", header = F)
colnames(processing_df) <- c("time_process_1500", "file_order")

print(processing_df) # testing

row = 1
for (file_no in processing_df["file_order"]) {
    processing_df[row, "solo_bases_process_1500"] <- all_end_times_df[file_no, "solo_bases_1500"]
    row = row + 1
}

print(processing_df) # testing





sequenced_bases_vs_time <- plot_ly(all_end_times_df,
                                   x = ~time_1500, y = ~tot_bases_1500, name = "1500",
                                   type = "scatter", mode = "lines") %>%
                            add_trace(x = ~processing_df["time_process_1500"], 
                                      y = ~processing_df["tot_bases_process_5000"], 
                                      name = "processing 5000") %>%
                            add_trace(x = ~time_5000, y = ~tot_bases_5000, name = "5000") %>%
                            add_trace(x = ~time_NA, y = ~tot_bases_NA, name = "NA") %>%
                            layout(title = "Bases Sequenced Over Time",
                                    xaxis = list(title = "Time (h)"),
                                    yaxis = list(title = "Gigabases Sequenced"))

sequenced_files_vs_time <- plot_ly(all_end_times_df,
                                   x = ~time_1500, name = "1500",
                                   type = "scatter", mode = "lines") %>%
                            add_trace(x =~time_5000, name = "5000") %>%
                            add_trace(x =~time_NA, name = "NA") %>%
                            layout(title = "Files Sequenced Over Time",
                                    xaxis = list(title = "Time (h)"),
                                    yaxis = list(title = "Number of Files Sequenced"))

plotly_IMAGE(sequenced_bases_vs_time, format = "png", out_file = "sequenced_bases_vs_time.png")
plotly_IMAGE(sequenced_files_vs_time, format = "png", out_file = "sequenced_files_vs_time.png")

#options(browser = "false")
#api_create(sequenced_bases_vs_time, filename = "sequenced_bases_vs_time", sharing = "public")
#api_create(sequenced_files_vs_time, filename = "sequenced_files_vs_time", sharing = "public")
