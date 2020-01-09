#!/usr/bin/env Rscript

end_times_vec <- vector() # declare empty vector

seq_sum_files <- list.files(path = "../../realf5p_data/1500",
                            pattern = "s*.txt$",
                            full.names = T,
                            recursive = F)

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
}

sort(end_times_vec)
file_number <- c(1:length(seq_sum_files))

require(plotly)
plot_ly(x = seq_sum_files, y = file_number, type = "scatter", mode = "lines")
