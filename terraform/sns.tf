resource "aws_sns_topic" "user_events" {
  name = "${var.sns_topics_prefix}-user-events-${var.environment}"

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-${var.environment}-sns-user-events" }
  )
}

resource "aws_sns_topic" "agenda_events" {
  name = "${var.sns_topics_prefix}-agenda-events-${var.environment}"

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-${var.environment}-sns-agenda-events" }
  )
}

resource "aws_sns_topic" "notifications" {
  name = "${var.sns_topics_prefix}-notifications-${var.environment}"

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-${var.environment}-sns-notifications" }
  )
}

resource "aws_sns_topic" "box_events" {
  name = "${var.sns_topics_prefix}-box-events-${var.environment}"

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-${var.environment}-sns-box-events" }
  )
}
