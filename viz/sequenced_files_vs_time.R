#!/usr/bin/env Rscript
.libPaths("~/R_packages")
require(plotly)

Sys.setenv("plotly_username" = "sjen")
Sys.setenv("plotly_api_key" = "7xblqr4HsNp3qVueLko0")

end_times_list <- list() # declare empty list

paths = c("../../realf5p_data/1500",
          "../../realf5p_data/5000")

for (data_dir in paths) {
    seq_sum_files <- list.files(path = data_dir,
                                pattern = "s*.txt$",
                                full.names = T,
                                recursive = F)
    
    end_times_vec <- vector() # declare empty vector
    for (i in 1:length(seq_sum_files)) {
        seq_sum_df <- read.table(seq_sum_files[i],
                                 sep = "\t",
                                 header = T)

        end_time <- 0
        for (row in 1:nrow(seq_sum_df)) {
            start_time <- seq_sum_df[row, 5]
            duration <- seq_sum_df[row, 6]

            if (start_time + duration > end_time) {
                end_time <- start_time + duration
            }
        }

        end_times_vec <- c(end_times_vec, end_time)
        end_times_vec <- sort(end_times_vec) / 3600 # Get time in hours (3600s in 1h)
    }
    cat("end_times_vec for ", data_dir, ": \n", end_times_vec, "\n")
    
    end_times_list[data_dir] <- list(end_times_vec)
}

print(end_times_list)

end_times_df <- data.frame(matrix(unlist(end_times_list)), nrow = length(end_times_list), byrow = T)

sequenced_files_vs_time <- plot_ly(end_times_df, x =~../../realf5p_data/1500, y = c(1, nrow(end_times_df)),
                                   name = "1500", type = "scatter", mode = "lines") %>%
                            add_trace(x =~../../realf5p_data/5000, name = "5000") %>%
                            layout(title = "Files Sequenced Over Time",
                                    xaxis = list(title = "Time (h)"),
                                    yaxis = list(title = "Number of Files Sequenced"))                               
plotly_IMAGE(sequenced_files_vs_time, format = "png", out_file = "sequenced_files_vs_time.png")

options(browser = "false")
api_create(sequenced_files_vs_time, filename = "sequenced_files_vs_time", sharing = "public")
