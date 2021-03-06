/*
 * \copyright Copyright (c) 2016 Governikus GmbH & Co. KG
 */

#include "VersionNumber.h"

#include <QCoreApplication>
#include <QGlobalStatic>

using namespace governikus;

Q_GLOBAL_STATIC_WITH_ARGS(VersionNumber, AppVersionNumber, (QCoreApplication::applicationVersion()))

const VersionNumber &VersionNumber::getApplicationVersion()
{
	return *AppVersionNumber;
}

VersionNumber::VersionNumber(const QString& pVersion)
	: mVersionNumber()
	, mSuffix()
{
	// do not initialize idx, otherwise you will trap into
	// a gcc bug: https://bugs.alpinelinux.org/issues/7584
	int idx;
	mVersionNumber = QVersionNumber::fromString(pVersion, &idx);
	mSuffix = pVersion.mid(idx).trimmed();
}


const QVersionNumber& VersionNumber::getVersionNumber() const
{
	return mVersionNumber;
}


bool VersionNumber::isDeveloperVersion() const
{
	return mVersionNumber.isNull() || (mVersionNumber.minorVersion() & 1) || !mSuffix.isEmpty();
}


int VersionNumber::getDistance() const
{
	const int indexStart = mSuffix.indexOf(QChar('+')) + 1;
	const int indexEnd = mSuffix.indexOf(QChar('-'), indexStart);
	if (indexStart && indexEnd)
	{
		bool ok;
		int value = mSuffix.mid(indexStart, indexEnd - indexStart).toInt(&ok);
		if (ok)
		{
			return value;
		}
	}

	return -1;
}


QString VersionNumber::getBranch() const
{
	const int indexStart = mSuffix.indexOf(QChar('-')) + 1;
	const int indexEnd = mSuffix.indexOf(QChar('-'), indexStart);
	if (indexStart && indexEnd)
	{
		return mSuffix.mid(indexStart, indexEnd - indexStart);
	}

	return QString();
}


QString VersionNumber::getRevision() const
{
	if (mSuffix.count(QChar('-')) > 1)
	{
		const int index = mSuffix.lastIndexOf(QChar('-')) + 1;
		if (index)
		{
			return mSuffix.mid(index);
		}
	}

	return QString();
}


bool VersionNumber::isDraft() const
{
	return mSuffix.contains(QStringLiteral("-draft")) || mSuffix.contains(QStringLiteral("-secret"));
}
