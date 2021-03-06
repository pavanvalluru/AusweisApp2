/*!
 * DidList.h
 *
 * \brief Class represents the retrieved PAOS DIDList.
 *
 * \copyright Copyright (c) 2014 Governikus GmbH & Co. KG
 */

#pragma once

#include "paos/element/ConnectionHandle.h"
#include "paos/ElementDetector.h"
#include "paos/PaosMessage.h"

namespace governikus
{

class DIDList
	: public PaosMessage
	, private ElementDetector
{
	private:
		ConnectionHandle mConnectionHandle;

		void parse();
		bool handleFoundElement(const QString& pElementName, const QString& pValue, const QXmlStreamAttributes& pAttributes) override;
		bool handleFoundElementConnectionHandle(const QString& pElementName, const QString& pValue);

	public:
		DIDList(const QByteArray& pXmlData);
		const ConnectionHandle& getConnectionHandle() const;
};

} /* namespace governikus */
