Dublin Marathon
================
2024-02-19

#### Work distribution

The report is a collaborative effort covering Introduction, Data
Wrangling, Analysis and Conclusion. Each of our individual contribution
to the questions formed is mentioned below.

### Introduction

The project focuses on Exploratory Data Analysis (EDA) of the Dublin
Marathon Finishers dataset from the year 2022. Through data
visualization and statistical analysis, we aim to reveal the patterns
and insights into the performance and demographics of marathon
participants. The dataset includes participant details such as names,
ages, genders, club affiliations, and various race metrics, offering a
comprehensive overview of their performance. Our exploration will
investigate factors like overall time, gender, age and various club
impact, thus providing valuable insights into the distribution and
characteristics of Dublin Marathon participants.

### Data Wrangling

The code below performs data wrangling on the dataset. It begins by
loading the dataset and addressing missing values, filling the “Club”
column with “UNKNOWN” for consistency. Uninformative columns are then
removed. Rows indicating runners who did not finish (DNF) are separated
into a different dataset for further investigation. Duplicated rows are
identified and removed. Finally, rows with missing values are
eliminated. The resulting “marathon_data” is now refined and ready for
analysis, ensuring data integrity and addressing issues like missing,
duplicated, and uninformative information.

``` r
library(dplyr)
library(tidyverse)
library(ggplot2)
library(GGally)

# Load DataSet
marathon_data <- read.csv('dublin2022marathon.csv')

# Identify columns with missing values
missing_cols <- colnames(marathon_data)[colSums(is.na(marathon_data)|
                                                  marathon_data == "") > 0]

# Fill missing value Club column with UNKNOWN value to avoid data discrepancy
marathon_data$Club <- ifelse(is.na(marathon_data$Club) | 
                               marathon_data$Club == "" | 
                               marathon_data$Club == " ", "UNKNOWN",
                             marathon_data$Club)

# Remove uninformative columns
marathon_data <- select(marathon_data, -c("Photo", "YouTube", "Share",
                                          "Chip.Time", "Chip.Position"))

# Move values with DNF (did not finish) data as a different dataset to investigate further based on age and gender on why they were not able to finish the marathon
dnf_rows <- apply(marathon_data, 1, function(row) any(row == "DNF"))
dnf_data <- marathon_data[dnf_rows, ]

# Remove DNF values from dataset
marathon_data <- marathon_data[!dnf_rows, ]

# Check for any duplicated values
columns_to_check <- c("First.Name", "Surname", "Gender", "Gender.Position",
                      "Category", "Category.Position", "Club",
                      "Overall.Position")

duplicate_rows <- duplicated(marathon_data[, columns_to_check])
duplicate_data <- marathon_data[duplicate_rows, ]

# Remove rows with missing values - only around 500 entries
missing_rows <- apply(marathon_data, 1,
                      function(row) any(is.na(row) | row == ""))
missing_data <- marathon_data[missing_rows, ]

marathon_data <- marathon_data[!missing_rows, ]
```

### Analysis

#### 1. Visualizing the correlation between half time and finish time

``` r
marathon_data$Gender <- as.factor(marathon_data$Gender)
marathon_data <- marathon_data |>
  mutate(
    FinalInSec = period_to_seconds(hms(Gun.Time)),
    MidInSec = period_to_seconds(hms(HALFWAY))
    )

marathon_data <- marathon_data |>
  mutate(SecondHalfSec = FinalInSec - MidInSec) 

ggplot(marathon_data, 
       aes(x=MidInSec, y=SecondHalfSec, colour = Gender)) + 
  geom_jitter() +
  geom_smooth() +
  scale_x_continuous(limits = c(4000, 15000)) + 
  scale_y_continuous(limits = c(4000, 18000)) + 
  xlab("Seconds for First Half of Race") + 
  ylab("Seconds for Second Half of Race")
```

<figure>
<img src="dublinMarathon_files/figure-gfm/unnamed-chunk-2-1.png"
alt="Scatterplot illustrating the correlation between time taken for first and second half of the marathon. Each point represents a participant’s performance, and the smooth line indicates the overall trend." />
<figcaption aria-hidden="true">Scatterplot illustrating the correlation
between time taken for first and second half of the marathon. Each point
represents a participant’s performance, and the smooth line indicates
the overall trend.</figcaption>
</figure>

``` r
pval<-t.test(marathon_data$MidInSec, marathon_data$SecondHalfSec, 
          paired = T)$p.value
```

While the performances in first half and second half race are
significantly different and correlated, an athlete’s second half
performance tends to be worse than their first half (their difference
tends to be positive on average). Also the difference on performance 
between genders expands for lower-tiered atheletes, and female ones 
tend to perform better than male ones. 

#### 2. Visualising relationship between Club Affiliation and Overall Time

``` r
club_summary <- marathon_data %>%
  group_by(Club) %>%
  summarise(
    MeanOverall = mean(FinalInSec, na.rm = TRUE),
    MedianOverall = median(FinalInSec, na.rm = TRUE),
    MinOverall = min(FinalInSec, na.rm = TRUE),
    MaxOverall = max(FinalInSec, na.rm = TRUE)
  )

top_clubs <- club_summary %>%
  arrange(MedianOverall) %>%
  slice_head(n = 20) 

# Visualize relationship between Club Affiliation and Overall Time
ggplot(top_clubs, aes(x = reorder(Club, MedianOverall), y = MedianOverall)) +
  geom_point() +
  geom_segment(aes(xend = fct_reorder(Club, MedianOverall)), yend = 0, col = "lightblue") +
  labs(title = "Clubs Affiliation and Finish Time") +
  xlab("Club")+ ylab("Finish Time(seconds)")+
  coord_flip()
```

<figure>
<img src="dublinMarathon_files/figure-gfm/unnamed-chunk-3-1.png"
alt="Scatter plot depicting the relationship between club affiliation and finish time for the top 20 clubs based on median overall time. The points represent the median finish time, while the connecting lines highlight the distribution of overall time taken within each club." />
<figcaption aria-hidden="true">Scatter plot depicting the relationship
between club affiliation and finish time for the top 20 clubs based on
median overall time. The points represent the median finish time, while
the connecting lines highlight the distribution of overall time taken
within each club.</figcaption>
</figure>

``` r
filtered_data <- marathon_data %>%
  filter(Club != "UNKNOWN")%>%
  select(Club, FinalInSec)

anova_result <- aov(FinalInSec ~ Club, data = filtered_data)
a<-summary(anova_result)
a1<-cor.test(club_summary$MeanOverall, club_summary$MedianOverall)
```

The scatterplot identifies top-performing clubs BRIDGE END A.C., ARMAGH
A.C., and CORK TRACK CLUB, based on their lowest median finish times.
However, the presence of UNKNOWN affiliations,as in data of joining any
club is not present, especially within the top five positions, raises
uncertainty about club associations. ANOVA results confirm a significant
difference in mean finish times among clubs (p \< 0.001), emphasizing
the influence of club affiliation on performance. The strong positive
correlation between Mean and Median Overall Positions signals consistent
and stable performance patterns within each club.

#### 3. Visualizing Runners Finish time based on Gender

``` r
t<-t.test(FinalInSec ~ Gender, data = marathon_data)

ggplot(marathon_data, aes(x = Gender, y = FinalInSec,fill = Gender)) +
  geom_boxplot() +
  labs(title = "Overall Time by Gender",
       x = "Gender",
       y = "Overall Time(seconds)")
```

<figure>
<img src="dublinMarathon_files/figure-gfm/unnamed-chunk-4-1.png"
alt="Boxplot illustrating distribution of Overall time taken by male and female participants in the marathon, with the x-axis representing the genders and the y-axis representing Overall time" />
<figcaption aria-hidden="true">Boxplot illustrating distribution of
Overall time taken by male and female participants in the marathon, with
the x-axis representing the genders and the y-axis representing Overall
time</figcaption>
</figure>

The boxplot compares the Overall time taken by male and female
participants and reveals that, on average, females took longer to
finish. Median gun time for females is higher than males. Also, the male
group exhibits greater variability in performance, with some
exceptionally slower times. More outliers and greater variance in one
gender can influence the average Gun time for that group. As the p_value
\<0.05, we can confirm there is a significant difference in the average
finish time between male and female participants.

#### 4. Visualising Performance Metrics across various Age Categories

``` r
marathon_data<- marathon_data |>
 select(1:21) |>
separate(Category,into=c('Category','Age'),sep=1)
 
marathon_data <- marathon_data |>
  mutate(
    FinalInMins = period_to_seconds(hms(Gun.Time))/60)

# Summarize data by Age_Category
summary_by_age <- marathon_data %>%
  group_by(Age) %>%
  reframe(
    Category,
    Mean_Time = mean(FinalInMins, na.rm = TRUE),
    Median_Time = median(FinalInMins, na.rm = TRUE),
    SD_Time = sd(FinalInMins, na.rm = TRUE),
    Total_Participants = n()
  )

# Visualize Performance Metrics
ggplot(summary_by_age, aes(x = factor(Age, levels = c('S','35','40','45','50','55','60','65','70','75','80')), 
                           y = Mean_Time, fill = Category)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Barplot of Overall Time by Age and Gender",
       x = "Age",
       y = "Overall Time") 
```

<figure>
<img src="dublinMarathon_files/figure-gfm/unnamed-chunk-5-1.png"
alt="Barplot representing overall time of participants across various age groups and genders. Each bar corresponds to a specific age category, with different colors for distinct gender groups. Height of each bar illustrates average overall time for participants." />
<figcaption aria-hidden="true">Barplot representing overall time of
participants across various age groups and genders. Each bar corresponds
to a specific age category, with different colors for distinct gender
groups. Height of each bar illustrates average overall time for
participants.</figcaption>
</figure>

The plot highlights a observable correlation between performance and age
in the marathon. Notably, participants in the 70-80 age group exhibit
the longest completion times, while the 35-40 age group demonstrates the
shortest. It’s noteworthy that there are no female participants in the
80-year age group. Overall, there’s a negative impact of age on
performance, indicating a trend of decreasing performance with
increasing age.

#### 5. Visualising the Stage Position Change for top 5 Performers

*General analysis of all members of the team*

``` r
marathon_data<- marathon_data |>
  mutate(Overall.Position=as.numeric(Overall.Position))

top_three_performers <- marathon_data %>%
  arrange(Overall.Position) %>%
  head(5) %>% 
  mutate(across(starts_with(c("Overall.Position", "Stage.Position")),
                as.character)) %>%
  pivot_longer(cols = starts_with(c("Stage.Position", "Overall.Position")),
               names_to = "Stage",
               values_to = "Position") %>%
  mutate(Stage = forcats::fct_inorder(Stage),
         Position = as.numeric(Position))  

ggplot(top_three_performers, aes(x = Stage, y = Position, 
                                color = First.Name, 
                                group = paste(First.Name, Surname))) +
  geom_line() +
  geom_point() +
  labs(x = "Race Stage",
       y = "Position",
       title = "Stage Position Change for top 5 Performers") +
  scale_color_manual(values = c("red", "blue", "green", "purple", "orange")) +
  scale_x_discrete(labels = c("10K", "20K", "HALFWAY", "30K", "40K", "FINAL")) +
  scale_y_continuous(breaks =seq(1,12,1))
```

<figure>
<img src="dublinMarathon_files/figure-gfm/unnamed-chunk-6-1.png"
alt="The graph illustrates the stage position changes for the top five performers in the marathon. Each line with distinct colors represents an individual performer. X-axis corresponds to different race stages, while y-axis indicates the position of each performer at those stages." />
<figcaption aria-hidden="true">The graph illustrates the stage position
changes for the top five performers in the marathon. Each line with
distinct colors represents an individual performer. X-axis corresponds
to different race stages, while y-axis indicates the position of each
performer at those stages.</figcaption>
</figure>

The plot reveals how the top 5 performers’ stage positions evolve
throughout the marathon. It emphasizes that the initial positions of
participants don’t necessarily determine their final standings. Notable
examples include “Taoufik Allam,” starting in 5th place but finishing
1st through consistent improvement, and “Craig Curley,” who, despite an
initial 12th position, secured 5th place with steady performance. This
underscores the significance of sustained excellence over the race,
indicating that ongoing performance matters more than the starting
position alone.

### Conclusion

The analysis points to Clubs BRIDGE END A.C., ARMAGH A.C., and CORK
TRACK CLUB as the most favorable choices for marathon participation,
with runners in it achieving better Overall Time. Notably, a positive
correlation exists between performances in the first and second halves
of the race, emphasizing the significance of pacing. Male participants
generally outperform their female counterparts, indicating a
gender-based performance gap. Additionally, a noteworthy relationship
between age and performance suggests the need for tailored training
approaches for different age groups.
